# frozen_string_literal: true

class Components::Button < Components::Base
  VARIANTS = {
    filled: "bg-(--app-primary) text-white hover:bg-(--app-primary-strong) disabled:opacity-50",
    outlined: "border border-gray-300 hover:bg-gray-50",
    tonal: "bg-(--app-container) text-(--app-primary) hover:bg-(--app-container-strong)"
  }.freeze

  def initialize(label, on: nil, variant: :filled, grow: false, target: nil, submit: false)
    @label = label
    @on = on
    @variant = variant
    @grow = grow
    @target = target
    @submit = submit
  end

  def view_template
    button(
      type: (@submit ? "submit" : "button"),
      class: [ "rounded-full px-6 py-3 font-medium", VARIANTS.fetch(@variant), (@grow ? "flex-1" : nil) ],
      data: on_data(@on).merge(target_data(@target))
    ) { @label }
  end
end
