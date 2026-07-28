# frozen_string_literal: true

# The one way words land on screen. Tone/size/weight from closed maps;
# `target:` lets a Stimulus controller own the content.
class Components::Text < Components::Base
  TONES = {
    nil => nil,
    muted: "text-gray-500",
    faint: "text-gray-400",
    danger: "text-(--app-danger)",
    primary: "text-(--app-primary)"
  }.freeze
  SIZES = { nil => nil, xs: "text-xs", sm: "text-sm", lg: "text-lg", xl: "text-xl" }.freeze
  WEIGHTS = { nil => nil, medium: "font-medium", semibold: "font-semibold" }.freeze

  def initialize(content = nil, tone: nil, size: nil, weight: nil, truncate: false, target: nil)
    @content = content
    @tone = tone
    @size = size
    @weight = weight
    @truncate = truncate
    @target = target
  end

  def view_template
    span(class: [
      TONES.fetch(@tone), SIZES.fetch(@size), WEIGHTS.fetch(@weight),
      (@truncate ? "block truncate" : nil)
    ], data: target_data(@target)) { @content }
  end
end
