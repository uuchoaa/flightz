module Settings
  # Partial update over the known keys: absent keys keep their value,
  # invalid ones fail the whole command as field errors. Returns the full
  # merged settings so the client can swap its cache atomically.
  class UpdateSettings
    PAYLOAD = %i[locale].freeze

    def call(payload)
      changes = payload.slice(*PAYLOAD).compact.transform_keys(&:to_s)
      return Result.err(:nothing_understood) if changes.empty?

      errors = validate(changes)
      return Result.err(:invalid, errors) if errors.any?

      changes.each { |key, value| Setting.put(key, value.to_s) }
      Result.ok(Defaults.current)
    end

    private

    def validate(changes)
      errors = {}
      if changes.key?("locale") && !Defaults::LOCALES.include?(changes["locale"].to_s)
        errors["locale"] = [ "must be one of: #{Defaults::LOCALES.join(', ')}" ]
      end
      errors
    end
  end
end
