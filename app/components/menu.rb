# frozen_string_literal: true

# A popover menu on a native details/summary — no JS to open. When it sits
# inside a clickable row, `skip_row_click:` keeps the row action away.
class Components::Menu < Components::Base
  def initialize(label, skip_row_click: false)
    @label = label
    @skip_row_click = skip_row_click
  end

  def view_template(&)
    details(class: "relative inline-block", data: (@skip_row_click ? { drawer_skip: true } : {})) do
      summary(
        class: "list-none cursor-pointer border border-(--app-primary) text-(--app-primary) rounded-lg " \
               "px-4 py-1 text-sm hover:bg-(--app-container) select-none [&::-webkit-details-marker]:hidden"
      ) { @label }
      div(class: "absolute z-10 mt-1 bg-white border border-gray-200 rounded-xl shadow-lg py-1 min-w-36", &)
    end
  end
end
