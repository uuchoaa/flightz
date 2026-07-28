require "rails/generators/active_record"

module Clean
  # Wires an AR edge between two existing entities the declarative way:
  # a reversible migration (add_reference, optional scoped-unique index or
  # column replacement) plus the belongs_to/has_many pair injected into the
  # entity files. Domain-blind, no inference -- references/belongs_to is the
  # closed vocabulary; the human declares the edge.
  #
  #   rails g clean:relate room belongs_to:place --scope-unique=name
  #   rails g clean:relate item belongs_to:room  --replace-column=room
  class RelateGenerator < Rails::Generators::NamedBase
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    argument :association, type: :string, banner: "belongs_to:parent"

    class_option :scope_unique, type: :string, default: nil,
                 desc: "field on the child made unique per parent (composite index + scoped validation)"
    class_option :replace_column, type: :string, default: nil,
                 desc: "existing child column to drop, replaced by the reference"

    def validate_association
      return if kind == "belongs_to"

      raise Thor::Error, "clean:relate only supports belongs_to:<parent> (got #{association.inspect})"
    end

    def create_migration_file
      migration_template "relate_migration.rb.tt",
                         "db/migrate/relate_#{file_name}_to_#{parent}.rb"
    end

    def inject_belongs_to
      inject_into_file child_entity_path, "  belongs_to :#{parent}\n",
                       after: /class #{class_name} < ApplicationRecord\n/
    end

    def inject_has_many
      inject_into_file parent_entity_path, "  has_many :#{child_plural}, dependent: :restrict_with_error\n",
                       after: /class #{parent.camelize} < ApplicationRecord\n/
    end

    # Best-effort: scope an existing global-unique validation to the parent.
    # A no-op if the child does not validate uniqueness on that field.
    def scope_uniqueness_validation
      return unless scope_unique

      gsub_file child_entity_path,
                /(validates :#{scope_unique},[^\n]*?)uniqueness: true/,
                "\\1uniqueness: { scope: :#{parent}_id }",
                verbose: false
    end

    private

    def kind = association.split(":").first
    def parent = association.split(":").last

    def scope_unique = options[:scope_unique].presence
    def replace_column = options[:replace_column].presence

    def child_plural = file_name.pluralize
    def child_entity_path = "app/entities/#{file_path}.rb"
    def parent_entity_path = "app/entities/#{parent}.rb"

    def relate_migration_class_name = "Relate#{class_name}To#{parent.camelize}"
  end
end
