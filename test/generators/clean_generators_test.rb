require "test_helper"
require "rails/generators"
require Rails.root.join("lib/generators/clean/entity/entity_generator")
require Rails.root.join("lib/generators/clean/use_case/use_case_generator")
require Rails.root.join("lib/generators/clean/query/query_generator")
require Rails.root.join("lib/generators/clean/component/component_generator")
require Rails.root.join("lib/generators/clean/relate/relate_generator")

# Tier 1 is tested code: what makes gem extraction trivial later.
module CleanGeneratorFixtures
  REGISTRY = <<~RUBY
    module Registry
      COMMANDS = {
        # clean:commands
      }.freeze

      QUERIES = {
        # clean:queries
      }.freeze
    end
  RUBY

  LOCALES = "en:\n  commands:\n    # clean:notices\n"

  def prepare_ring_files
    FileUtils.mkdir_p(File.join(destination_root, "app/use_cases"))
    File.write(File.join(destination_root, "app/use_cases/registry.rb"), REGISTRY)
    FileUtils.mkdir_p(File.join(destination_root, "config/locales"))
    File.write(File.join(destination_root, "config/locales/commands.en.yml"), LOCALES)
  end
end

class CleanEntityGeneratorTest < Rails::Generators::TestCase
  tests Clean::EntityGenerator
  destination Rails.root.join("tmp/generator_tests/entity")
  setup :prepare_destination

  test "entity lands in the entity ring, never app/models" do
    run_generator %w[widget name:string owner:references amount_cents:integer]
    assert_migration "db/migrate/create_widgets.rb", /create_table :widgets/, /t\.references :owner/
    assert_file "app/entities/widget.rb", /class Widget < ApplicationRecord/, /belongs_to :owner/
    assert_file "test/entities/widget_test.rb"
    assert_file "test/fixtures/widgets.yml"
    assert_no_file "app/models/widget.rb"
  end
end

class CleanUseCaseGeneratorTest < Rails::Generators::TestCase
  include CleanGeneratorFixtures

  tests Clean::UseCaseGenerator
  destination Rails.root.join("tmp/generator_tests/use_case")
  setup { prepare_destination; prepare_ring_files }

  test "handler, registry entry, notice and red test" do
    run_generator %w[shop/add_widget name amount_cents]
    assert_file "app/use_cases/shop/add_widget.rb",
                /module Shop/, /class AddWidget/, /PAYLOAD = %i\[name amount_cents\]\.freeze/,
                /NotImplementedError/
    assert_file "app/use_cases/registry.rb", /"add_widget" => Shop::AddWidget,/
    assert_file "config/locales/commands.en.yml", /add_widget:\n      done:/
    assert_file "test/use_cases/shop/add_widget_test.rb", /assert_kind_of Result/
  end
end

class CleanQueryGeneratorTest < Rails::Generators::TestCase
  include CleanGeneratorFixtures

  tests Clean::QueryGenerator
  destination Rails.root.join("tmp/generator_tests/query")
  setup { prepare_destination; prepare_ring_files }

  test "query object and registry entry" do
    run_generator %w[shop/widgets room]
    assert_file "app/use_cases/shop/queries/widgets.rb",
                /module Shop/, /module Queries/, /class Widgets/, /NotImplementedError/
    assert_file "app/use_cases/registry.rb", /"widgets" => Shop::Queries::Widgets,/
    assert_file "test/use_cases/shop/queries/widgets_test.rb"
  end
end

class CleanRelateGeneratorTest < Rails::Generators::TestCase
  tests Clean::RelateGenerator
  destination Rails.root.join("tmp/generator_tests/relate")
  setup :prepare_destination

  def write_entity(name, body = "")
    FileUtils.mkdir_p(File.join(destination_root, "app/entities"))
    File.write(File.join(destination_root, "app/entities/#{name}.rb"),
               "class #{name.camelize} < ApplicationRecord\n#{body}end\n")
  end

  test "scoped belongs_to injects the pair, composite index and scoped validation" do
    write_entity "place"
    write_entity "room", "  validates :name, presence: true, uniqueness: true\n"

    run_generator %w[room belongs_to:place --scope-unique=name]

    assert_migration "db/migrate/relate_room_to_place.rb",
                     /class RelateRoomToPlace/,
                     /add_reference :rooms, :place, null: false, foreign_key: true/,
                     /remove_index :rooms, :name, if_exists: true/,
                     /add_index :rooms, %i\[place_id name\], unique: true/
    assert_file "app/entities/room.rb", /belongs_to :place/,
                /uniqueness: \{ scope: :place_id \}/
    assert_file "app/entities/place.rb", /has_many :rooms, dependent: :restrict_with_error/
  end

  test "replace-column drops the string and adds the reference" do
    write_entity "room"
    write_entity "item", "  belongs_to :nothing\n"

    run_generator %w[item belongs_to:room --replace-column=room]

    assert_migration "db/migrate/relate_item_to_room.rb",
                     /remove_column :items, :room/,
                     /add_reference :items, :room, null: false, foreign_key: true/,
                     /add_column :items, :room, :string/
    assert_file "app/entities/item.rb", /belongs_to :room/
    assert_file "app/entities/room.rb", /has_many :items, dependent: :restrict_with_error/
  end

  test "rejects associations other than belongs_to" do
    write_entity "place"
    write_entity "room"
    run_generator %w[room has_many:place]
    assert_no_migration "db/migrate/relate_room_to_place.rb"
    assert_file "app/entities/place.rb" do |content|
      assert_no_match(/has_many/, content)
    end
  end
end

class CleanComponentGeneratorTest < Rails::Generators::TestCase
  tests Clean::ComponentGenerator
  destination Rails.root.join("tmp/generator_tests/component")
  setup :prepare_destination

  test "htm component skeleton" do
    run_generator %w[widget_card]
    assert_file "app/javascript/components/widget_card.js",
                /import { html } from "lib\/html"/, /export function WidgetCard/
  end
end
