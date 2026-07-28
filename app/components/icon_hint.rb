# frozen_string_literal: true

# A small toned icon with a tooltip — a flag beside a value.
class Components::IconHint < Components::Base
  TONES = {
    nil => "text-gray-400",
    warn: "text-(--app-worn-ink)",
    danger: "text-(--app-danger)"
  }.freeze

  def initialize(icon, title: nil, tone: nil, size: 16)
    @icon = icon
    @title = title
    @tone = tone
    @size = size
  end

  def view_template
    span(title: @title, class: TONES.fetch(@tone)) { Icon(@icon, size: @size) }
  end
end
