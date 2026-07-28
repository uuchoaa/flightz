require "rails/generators/active_record"

module Clean
  # NL + vision quick-capture. Reads only the registry, never the domain
  # vocabulary — tier 1 machinery. Runs once, after clean:install.
  class CaptureGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def ledger_children
      migration_template "add_parent_to_commands.rb", "db/migrate/add_parent_to_commands.rb"
      inject_into_file "app/entities/command.rb", <<~RUBY.indent(2), after: "class Command < ApplicationRecord\n"
        belongs_to :parent, class_name: "Command", optional: true
        has_many :children, class_name: "Command", foreign_key: :parent_id, dependent: :destroy
      RUBY
    end

    def use_case
      copy_file "capture.rb", "app/use_cases/capture.rb"
      copy_file "capture_schema.rb", "app/use_cases/capture_schema.rb"
      inject_into_file "app/use_cases/registry.rb", %(    "capture" => Capture,\n),
                       after: "# clean:commands\n"
    end

    def photo_storage
      rails_command "active_storage:install"
    end

    def frontend
      copy_file "capture_bar.js", "app/javascript/components/capture_bar.js"
    end

    def locales
      inject_into_file "config/locales/commands.en.yml", <<~YAML.indent(4), after: "# clean:notices\n"
        capture:
          done: "Captured"
          proposed: "Found items — review and confirm"
      YAML
    end

    def tests
      copy_file "capture_test.rb", "test/use_cases/capture_test.rb"
    end
  end
end
