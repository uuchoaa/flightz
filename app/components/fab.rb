# frozen_string_literal: true

class Components::Fab < Components::Base
  def initialize(label, icon:, on:)
    @label = label
    @icon = icon
    @on = on
  end

  def view_template
    button(
      class: "fixed right-8 bottom-8 flex items-center gap-2 bg-(--app-container) text-(--app-primary) " \
             "rounded-2xl px-5 py-4 font-medium shadow-lg hover:bg-(--app-container-strong)",
      data: { action: @on }
    ) do
      Icon(@icon)
      span { @label }
    end
  end
end
