module Settings
  # The single source of the configurable surface: known keys and their
  # defaults.
  module Defaults
    VALUES = {
      "locale" => "en"
    }.freeze

    LOCALES = %w[pt-BR en].freeze

    def self.current
      VALUES.merge(Setting.all_values.slice(*VALUES.keys))
    end
  end
end
