# frozen_string_literal: true

class Components::MenuItem < Components::Base
  def initialize(label, on:)
    @label = label
    @on = on
  end

  def view_template
    button(class: "block w-full text-left px-4 py-2 text-sm hover:bg-gray-50", data: on_data(@on)) { @label }
  end
end
