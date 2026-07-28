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

  # The view layer's two laws (absorbed from cuy's `bin/cuy lint`). The
  # domain residue is the components NOT in the kit list: they speak the
  # domain but only through the kit's vocabulary.
  DOMAIN_COMPONENTS = %w[labels].freeze
  KIT = Dir[Rails.root.join("app/components/*.rb")]
        .reject { |f| DOMAIN_COMPONENTS.include?(File.basename(f, ".rb")) }
  KIT_JS = %w[lib/commands controllers/command_controller controllers/form_controller
              controllers/toast_controller controllers/search_controller]
           .map { |name| Rails.root.join("app/javascript/#{name}.js") }
  DOMAIN_WORDS = %w[
    flight flights airline airport itinerary fare layover voo aeroporto
    capture household
  ].freeze

  # Law 1: the agnostic kit never says a domain word — comments included.
  test "the kit says no domain word" do
    pattern = /\b(?:#{DOMAIN_WORDS.join('|')})\b/i
    violations = (KIT + KIT_JS).flat_map { |path| grep(path, pattern) }
    assert_empty violations, "the kit leaked domain vocabulary:\n#{violations.join("\n")}"
  end

  # Law 2: the app tier (screens + domain components) speaks ONLY the kit —
  # no native tags, no CSS classes, no splats.
  APP_TIER = Dir[Rails.root.join("app/views/*.rb")] +
             DOMAIN_COMPONENTS.map { |name| Rails.root.join("app/components/#{name}.rb") }
  NATIVE = /(?:^|[\s({])(?:div|span|p|a|h[1-6]|ul|li|button|input|select|option|textarea|label|form|table|thead|tbody|tr|td|th|details|summary|img|aside|nav|main|section|header|footer|small|strong|em)\(/
  FORBIDDEN_APP = [ NATIVE, /class:/, /\*\*/ ].freeze

  test "the app speaks only the kit" do
    violations = APP_TIER.flat_map do |path|
      FORBIDDEN_APP.flat_map { |pattern| grep(path, pattern) }
    end
    assert_empty violations, "the app tier left the kit vocabulary:\n#{violations.uniq.join("\n")}"
  end

  private

  def grep(path, pattern)
    File.foreach(path).with_index(1).filter_map do |line, lineno|
      "#{path.to_s.sub("#{Rails.root}/", '')}:#{lineno}: #{line.strip}" if line =~ pattern
    end
  end
end
