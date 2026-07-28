module Clean
  # A write use case: handler with PAYLOAD, registry entry behind the
  # sentinel, an I18n notice (infer-drafted, humanized fallback) and a red
  # test — failing until the handler is implemented.
  class UseCaseGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    argument :payload, type: :array, default: [], banner: "key key"

    def create_handler
      template "use_case.rb.tt", "app/use_cases/#{file_path}.rb"
    end

    def create_test
      template "use_case_test.rb.tt", "test/use_cases/#{file_path}_test.rb"
    end

    def register
      inject_into_file "app/use_cases/registry.rb",
                       %(    "#{file_name}" => #{class_name},\n),
                       after: "# clean:commands\n"
    end

    def notice
      inject_into_file "config/locales/commands.en.yml",
                       "    #{file_name}:\n      done: \"#{notice_copy}\"\n",
                       after: "# clean:notices\n"
    end

    private

    NOTICE_SCHEMA = {
      type: "object",
      properties: { notice: { type: "string", maxLength: 60 } },
      required: ["notice"],
    }.freeze

    def notice_copy
      drafted = Infer.structured(
        NOTICE_SCHEMA,
        prompt: "Write the short success toast (imperative past, plain text, no emoji) " \
                "shown after this application command succeeds.",
        context: { command: file_name, payload_keys: payload }
      )
      (drafted && drafted[:notice].presence) || "#{file_name.humanize} done"
    end
  end
end
