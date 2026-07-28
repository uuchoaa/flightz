require "test_helper"

# The dependency rule, executable: inward only. Entities reference nothing
# outward; use cases stay out of delivery; the registry is complete.
class ArchitectureTest < ActiveSupport::TestCase
  ENTITIES = Dir[Rails.root.join("app/entities/**/*.rb")]
  USE_CASES = Dir[Rails.root.join("app/use_cases/**/*.rb")]

  test "app/models does not exist" do
    assert_not Dir.exist?(Rails.root.join("app/models")),
               "use app/entities (clean:entity), not app/models"
  end

  test "entities reference nothing outward" do
    offenders = ENTITIES.select do |file|
      File.read(file) =~ /\b(Registry|Result|CommandJob|ActionCable|ApplicationController|Api::|Infer)\b/
    end
    assert_empty offenders.map { |f| f.sub("#{Rails.root}/", "") }
  end

  test "use cases stay out of delivery" do
    offenders = USE_CASES.select do |file|
      File.read(file) =~ /\b(ApplicationController|ActionCable|CommandJob|ActionController)\b/
    end
    assert_empty offenders.map { |f| f.sub("#{Rails.root}/", "") }
  end

  test "every command handler is registered" do
    registry = File.read(Rails.root.join("app/use_cases/registry.rb"))
    handlers = USE_CASES.reject { |f| f.end_with?("registry.rb") }
                        .select { |f| File.read(f).include?("PAYLOAD = ") }
    handlers.each do |file|
      klass = file[%r{app/use_cases/(.+)\.rb}, 1].camelize
      assert_includes registry, klass, "#{klass} missing from Registry::COMMANDS"
    end
  end

  test "every query is registered" do
    registry = File.read(Rails.root.join("app/use_cases/registry.rb"))
    Dir[Rails.root.join("app/use_cases/**/queries/*.rb")].each do |file|
      klass = file[%r{app/use_cases/(.+)\.rb}, 1].camelize
      assert_includes registry, klass, "#{klass} missing from Registry::QUERIES"
    end
  end
end
