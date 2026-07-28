# frozen_string_literal: true

# Material-style snackbar, filled by toast_controller on app:toast events.
class Components::Toast < Components::Base
  def view_template
    div(
      class: "hidden fixed bottom-6 left-6 z-50 rounded-lg px-4 py-3 text-sm text-white shadow-lg " \
             "bg-gray-900 data-[kind=err]:bg-(--app-danger) data-[kind=ok]:bg-gray-900 max-w-md",
      data: { controller: "toast" }
    ) do
      span(data: { toast_target: "message" })
    end
  end
end
