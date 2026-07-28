# frozen_string_literal: true

# Exclusive segmented picker; the Stimulus controller flips data-on and
# keeps a hidden input in sync (see target/on contract).
class Components::Segmented < Components::Base
  COLS = { 2 => "grid-cols-2", 3 => "grid-cols-3", 4 => "grid-cols-4" }.freeze

  def initialize(label = nil, options:, on:, target: nil)
    @label = label
    @options = options # [[value, text], ...]
    @on = on
    @target = target
  end

  def view_template
    div do
      span(class: "block text-sm mb-2") { @label } if @label
      div(class: [ "grid border border-gray-300 rounded-xl overflow-hidden", COLS.fetch(@options.size) ]) do
        @options.each do |value, text|
          button(
            type: "button",
            class: "py-2 text-sm border-r border-gray-300 last:border-r-0 " \
                   "data-[on=true]:bg-(--app-container) data-[on=true]:text-(--app-primary) " \
                   "data-[on=true]:font-semibold",
            data: on_data(@on).merge(target_data(@target)).merge(value:)
          ) { text }
        end
      end
    end
  end
end
