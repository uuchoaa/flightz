# frozen_string_literal: true

# Column grid.
class Components::Grid < Components::Base
  COLS = { 2 => "grid-cols-2", 3 => "grid-cols-3", 4 => "grid-cols-4" }.freeze
  GAPS = { 0 => "gap-0", 2 => "gap-2", 4 => "gap-4" }.freeze

  def initialize(cols: 2, gap: 4)
    @cols = cols
    @gap = gap
  end

  def view_template(&)
    div(class: [ "grid", COLS.fetch(@cols), GAPS.fetch(@gap) ], &)
  end
end
