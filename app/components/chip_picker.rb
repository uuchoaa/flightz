# frozen_string_literal: true

# Exclusive chip picker; same data-on/target contract as Segmented.
class Components::ChipPicker < Components::Base
  def initialize(label = nil, options:, on:, target: nil)
    @label = label
    @options = options # [[value, text], ...]
    @on = on
    @target = target
  end

  def view_template
    div do
      span(class: "block text-sm mb-2") { @label } if @label
      div(class: "flex flex-wrap gap-2") do
        @options.each do |value, text|
          button(
            type: "button",
            class: "px-4 py-1.5 rounded-lg border border-gray-300 text-sm " \
                   "data-[on=true]:bg-(--app-container) data-[on=true]:border-(--app-primary) " \
                   "data-[on=true]:text-(--app-primary)",
            data: on_data(@on).merge(target_data(@target)).merge(value:)
          ) { text }
        end
      end
    end
  end
end
