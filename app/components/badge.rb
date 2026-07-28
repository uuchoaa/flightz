# frozen_string_literal: true

# A small pill; tones are semantic names, never classes at the call site.
class Components::Badge < Components::Base
  TONES = {
    neutral: "bg-gray-100 text-gray-600",
    info: "bg-(--app-container) text-(--app-primary)",
    good: "bg-(--app-good) text-(--app-good-ink)",
    warn: "bg-(--app-worn) text-(--app-worn-ink)",
    danger: "bg-(--app-broken) text-(--app-danger)"
  }.freeze

  def initialize(label, tone: :neutral)
    @label = label
    @tone = tone
  end

  def view_template
    span(class: "px-3 py-1 rounded-full text-sm font-semibold #{TONES.fetch(@tone)}") { @label }
  end
end
