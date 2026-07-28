require "rails/generators/active_record"

module Clean
  # Generates everything architecture.md calls machinery. Runs once.
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def entities_ring
      copy_file "application_record.rb", "app/entities/application_record.rb"
      remove_file "app/models"
    end

    def use_case_ring
      copy_file "result.rb", "app/use_cases/result.rb"
      copy_file "registry.rb", "app/use_cases/registry.rb"
    end

    def command_ledger
      migration_template "create_commands.rb", "db/migrate/create_commands.rb"
      copy_file "command.rb", "app/entities/command.rb"
    end

    def delivery_ring
      copy_file "command_job.rb", "app/jobs/command_job.rb"
      copy_file "application_cable_channel.rb", "app/channels/application_cable/channel.rb"
      copy_file "application_cable_connection.rb", "app/channels/application_cable/connection.rb"
      copy_file "commands_channel.rb", "app/channels/commands_channel.rb"
      copy_file "commands_controller.rb", "app/controllers/api/commands_controller.rb"
      copy_file "queries_controller.rb", "app/controllers/api/queries_controller.rb"
      copy_file "home_controller.rb", "app/controllers/home_controller.rb"
      copy_file "home_index.html.erb", "app/views/home/index.html.erb"
      route <<~ROUTES.chomp
        root "home#index"

          namespace :api do
            resources :commands, only: %i[create show]
            get "queries/:name", to: "queries#show", as: :query
          end
      ROUTES
    end

    def javascript_machinery
      copy_file "js/html.js", "app/javascript/lib/html.js"
      copy_file "js/cable.js", "app/javascript/lib/cable.js"
      copy_file "js/command.js", "app/javascript/lib/command.js"
      copy_file "js/toaster.js", "app/javascript/lib/toaster.js"
      copy_file "js/use_command.js", "app/javascript/lib/use_command.js"
      copy_file "js/toaster_component.js", "app/javascript/components/toaster.js"
      copy_file "js/image_input.js", "app/javascript/components/image_input.js"
      copy_file "js/app.js", "app/javascript/components/app.js"
      copy_file "js/application.js", "app/javascript/application.js", force: true
      append_to_file "config/importmap.rb", <<~RUBY
        pin_all_from "app/javascript/lib", under: "lib"
        pin_all_from "app/javascript/components", under: "components"
      RUBY
    end

    def locales
      copy_file "commands.en.yml", "config/locales/commands.en.yml"
    end

    def tests
      copy_file "architecture_test.rb", "test/architecture_test.rb"
      inject_into_file "test/test_helper.rb", "\nInfer.backend = Infer::Static.new\n",
                       after: %(require "rails/test_help"\n)
    end

    # Solid Queue in development, inside Puma: the whole W in one process.
    def development_w
      gsub_file "config/database.yml", <<~OLD, <<~NEW
        development:
          <<: *default
          database: storage/development.sqlite3
      OLD
        development:
          primary:
            <<: *default
            database: storage/development.sqlite3
          queue:
            <<: *default
            database: storage/development_queue.sqlite3
            migrations_paths: db/queue_migrate
          cable:
            <<: *default
            database: storage/development_cable.sqlite3
            migrations_paths: db/cable_migrate
      NEW
      environment(nil, env: "development") do
        <<~RUBY
          config.active_job.queue_adapter = :solid_queue
          config.solid_queue.connects_to = { database: { writing: :queue } }
        RUBY
      end
      gsub_file "Procfile.dev", "web: bin/rails server", "web: SOLID_QUEUE_IN_PUMA=1 bin/rails server"
      create_file "db/queue_migrate/.keep", ""

      # Solid Queue's Puma plugin forks workers; the async cable adapter only
      # delivers in-process, so confirms broadcast from workers would vanish.
      gsub_file "config/cable.yml", <<~OLD, <<~NEW
        development:
          adapter: async
      OLD
        development:
          adapter: solid_cable
          connects_to:
            database:
              writing: cable
          polling_interval: 0.1.seconds
          message_retention: 1.day
      NEW
      create_file "db/cable_migrate/.keep", ""
    end
  end
end
