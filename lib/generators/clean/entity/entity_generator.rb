require "rails/generators/active_record"

module Clean
  # The entity ring's own primitive: same moves as the stock model generator
  # (migration, model, test, fixture), landing in app/entities.
  class EntityGenerator < Rails::Generators::NamedBase
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def create_migration_file
      migration_template "create_table_migration.rb.tt", "db/migrate/create_#{table_name}.rb"
    end

    def create_entity
      template "entity.rb.tt", "app/entities/#{file_path}.rb"
    end

    def create_test
      template "entity_test.rb.tt", "test/entities/#{file_path}_test.rb"
    end

    def create_fixtures
      template "fixtures.yml.tt", "test/fixtures/#{fixture_file_name}.yml"
    end

    private

    def fixture_file_name
      (class_path + [plural_file_name]).join("/")
    end
  end
end
