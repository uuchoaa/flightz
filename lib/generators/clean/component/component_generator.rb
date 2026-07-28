module Clean
  # An htm React component skeleton over the Catalyst kit — no build step.
  class ComponentGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def create_component
      template "component.js.tt", "app/javascript/components/#{file_name}.js"
    end
  end
end
