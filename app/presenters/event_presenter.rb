# frozen_string_literal: true

# Wraps one ledger row for the logs table.
class EventPresenter
  TONES = { "done" => :good, "failed" => :danger, "pending" => :neutral }.freeze
  LEVEL_TONES = { "info" => :info, "debug" => :neutral }.freeze

  attr_reader :raw

  def initialize(raw)
    @raw = raw
  end

  def id = raw["id"].to_s
  def child? = raw["parent_id"].present?
  def error_code = raw.dig("result", "err", "code")

  # Debug rows are pipeline steps: show the same localized narration the
  # live console does, interpolating the step's captured data.
  def name
    return raw["name"] unless raw["level"] == "debug"

    data = (raw["payload"] || {}).to_h do |key, value|
      [ key.to_sym, value.is_a?(Array) ? value.join(", ") : value ]
    end
    I18n.t("flights.step.#{raw['name']}", default: raw["name"].to_s.humanize, **data)
  end

  def level
    label = I18n.t("logs.level.#{raw['level']}", default: raw["level"])
    Components::Badge.new(label, tone: LEVEL_TONES.fetch(raw["level"], :neutral))
  end

  def status
    label = I18n.t("logs.status.#{raw['status']}", default: raw["status"])
    Components::Badge.new(label, tone: TONES.fetch(raw["status"], :neutral))
  end

  def payload_summary
    text = (raw["payload"] || {})
           .reject { |_, value| value.nil? || value == "" }
           .map { |key, value| "#{key}: #{value.is_a?(Enumerable) ? value.to_json : value}" }
           .join(" · ")
    text.truncate(120)
  end

  def at
    I18n.l(Time.iso8601(raw["created_at"].to_s).in_time_zone, format: :short)
  end
end
