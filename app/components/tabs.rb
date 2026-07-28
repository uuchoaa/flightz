# frozen_string_literal: true

# A segmented row of link tabs (GET navigation, not a form). Each option is
# [value, label, href]; the one matching `active` is highlighted. Agnostic
# of what it filters.
class Components::Tabs < Components::Base
  def initialize(options:, active:)
    @options = options
    @active = active
  end

  def view_template
    div(class: "inline-flex border border-gray-300 rounded-xl overflow-hidden") do
      @options.each do |value, label, href|
        a(href:, class: [
          "px-4 py-1.5 text-sm border-r border-gray-300 last:border-r-0",
          (value == @active ? "bg-(--app-container) text-(--app-primary) font-semibold" : "text-gray-500 hover:bg-gray-100")
        ]) { label }
      end
    end
  end
end
