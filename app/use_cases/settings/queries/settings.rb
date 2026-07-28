module Settings
  module Queries
    # call(params) -> { values: } — the effective settings.
    class Settings
      def call(_params)
        { values: ::Settings::Defaults.current }
      end
    end
  end
end
