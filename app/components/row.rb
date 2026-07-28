# frozen_string_literal: true

# Horizontal layout: children centered on the cross axis.
class Components::Row < Components::Base
  GAPS = { 0 => "gap-0", 1 => "gap-1", 2 => "gap-2", 3 => "gap-3", 4 => "gap-4", 5 => "gap-5" }.freeze

  def initialize(gap: 2, between: false, wrap: false)
    @gap = gap
    @between = between
    @wrap = wrap
  end

  def view_template(&)
    div(class: [
      "flex items-center", GAPS.fetch(@gap),
      (@between ? "justify-between" : nil),
      (@wrap ? "flex-wrap" : nil)
    ], &)
  end
end
