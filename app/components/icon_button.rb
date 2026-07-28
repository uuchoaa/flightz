# frozen_string_literal: true

class Components::IconButton < Components::Base
  TONES = {
    nil => "text-gray-500 hover:bg-gray-100",
    danger: "text-(--app-danger) hover:bg-red-50",
    primary: "text-(--app-primary) hover:bg-(--app-container)"
  }.freeze

  def initialize(icon, on: nil, tone: nil, size: 20, title: nil, target: nil,
                 hidden: false, disabled: false, submit: false)
    @icon = icon
    @on = on
    @tone = tone
    @size = size
    @title = title
    @target = target
    @hidden = hidden
    @disabled = disabled
    @submit = submit
  end

  def view_template
    button(
      type: (@submit ? "submit" : "button"),
      title: @title,
      disabled: @disabled,
      class: [ "p-2 rounded-full", TONES.fetch(@tone), (@hidden ? "hidden" : nil),
              (@disabled ? "text-gray-400" : nil) ],
      data: on_data(@on).merge(target_data(@target))
    ) { Icon(@icon, size: @size) }
  end
end
