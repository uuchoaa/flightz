module Clean
  # A read-side query object: a named entry point over scopes, dispatched
  # via GET /api/queries/:name.
  class QueryGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    argument :params, type: :array, default: [], banner: "key key"

    def create_query
      template "query.rb.tt", "app/use_cases/#{namespace_path}/queries/#{file_name}.rb"
    end

    def create_test
      template "query_test.rb.tt", "test/use_cases/#{namespace_path}/queries/#{file_name}_test.rb"
    end

    def register
      inject_into_file "app/use_cases/registry.rb",
                       %(    "#{file_name}" => #{query_class_name},\n),
                       after: "# clean:queries\n"
    end

    private

    def namespace_path
      class_path.join("/")
    end

    def query_class_name
      (class_path.map(&:camelize) + ["Queries", file_name.camelize]).join("::")
    end
  end
end
