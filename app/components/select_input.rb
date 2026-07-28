# frozen_string_literal: true

class Components::SelectInput < Components::Base
  def initialize(label = nil, options:, target: nil, name: nil, blank: nil, selected: nil)
    @label = label
    @options = options # [[value, text], ...] or a flat list
    @target = target
    @name = name
    @blank = blank
    @selected = selected
  end

  def view_template
    field_frame(@label) do
      select(name: @name, class: FIELD_CLASSES, data: target_data(@target)) do
        option(value: "") { @blank } if @blank
        @options.each do |opt|
          value, text = opt.is_a?(Array) ? opt : [ opt, opt ]
          option(value:, selected: value.to_s == @selected.to_s) { text }
        end
      end
    end
  end
end
