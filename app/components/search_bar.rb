# frozen_string_literal: true

# Quick-filter bar over the rendered rows (search_controller) with a
# "visible of total" counter.
class Components::SearchBar < Components::Base
  def initialize(placeholder:, counter:)
    @placeholder = placeholder
    @counter = counter
  end

  def view_template
    div(class: "flex items-center gap-3 bg-(--app-surface) rounded-full px-5 py-2.5 mb-8") do
      Icon(:search, css: "text-gray-500 shrink-0")
      input(
        type: "text",
        placeholder: @placeholder,
        class: "flex-1 bg-transparent outline-none text-base",
        data: { search_target: "input", action: "input->search#update" }
      )
      span(class: "text-sm text-gray-500 whitespace-nowrap", data: { search_target: "count" }) do
        @counter
      end
    end
  end
end
