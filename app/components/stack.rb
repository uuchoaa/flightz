# frozen_string_literal: true

# Vertical layout.
class Components::Stack < Components::Base
  GAPS = { 0 => "gap-0", 1 => "gap-1", 2 => "gap-2", 3 => "gap-3", 4 => "gap-4", 5 => "gap-5" }.freeze

  def initialize(gap: 5, narrow: false)
    @gap = gap
    @narrow = narrow # constrain to a comfortable reading width
  end

  def view_template(&)
    div(class: [ "flex flex-col", GAPS.fetch(@gap), (@narrow ? "max-w-xl" : nil) ], &)
  end
end
