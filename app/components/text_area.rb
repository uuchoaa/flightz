# frozen_string_literal: true

class Components::TextArea < Components::Base
  def initialize(label = nil, target: nil, name: nil, placeholder: nil, rows: 3)
    @label = label
    @target = target
    @name = name
    @placeholder = placeholder
    @rows = rows
  end

  def view_template
    field_frame(@label) do
      textarea(rows: @rows, name: @name, placeholder: @placeholder,
               class: "w-full border border-gray-300 rounded-xl p-3 outline-none focus:border-(--app-primary)",
               data: target_data(@target))
    end
  end
end
