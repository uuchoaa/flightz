# frozen_string_literal: true

# Domain vocabulary is English (entities); the UI reads the locale files.
# All the mapping and formatting lives here so components never hardcode it.
module Components::Labels
  # Values are reais regardless of UI language — currency is the
  # household's, not the locale's.
  def brl(cents)
    return nil if cents.nil?

    whole, fraction = cents.divmod(100)
    formatted = whole.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
    fraction.zero? ? "R$ #{formatted}" : "R$ #{formatted},#{format('%02d', fraction)}"
  end

  def relative_time(iso)
    return "" if iso.blank?

    minutes = ((Time.current - Time.iso8601(iso.to_s)) / 60).round.clamp(0..)
    return I18n.t("time.ago_minutes", count: minutes) if minutes < 60
    return I18n.t("time.ago_hours", count: minutes / 60) if minutes < 24 * 60

    I18n.t("time.ago_days", count: minutes / (24 * 60))
  end
end
