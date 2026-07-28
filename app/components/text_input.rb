# frozen_string_literal: true

class Components::TextInput < Components::Base
  def initialize(label = nil, target: nil, name: nil, placeholder: nil, type: :text, required: false)
    @label = label
    @target = target
    @name = name
    @placeholder = placeholder
    @type = type
    @required = required
  end

  def view_template
    field_frame(@label) do
      input(type: @type, name: @name, placeholder: @placeholder, required: @required,
            class: FIELD_CLASSES, data: target_data(@target))
    end
  end
end
