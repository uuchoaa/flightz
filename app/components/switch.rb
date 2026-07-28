# frozen_string_literal: true

class Components::Switch < Components::Base
  def initialize(label, target: nil, name: nil)
    @label = label
    @target = target
    @name = name
  end

  def view_template
    label(class: "flex items-center justify-between cursor-pointer") do
      span { @label }
      input(type: "checkbox", name: @name, class: "w-5 h-5 accent-(--app-primary)",
            data: target_data(@target))
    end
  end
end
