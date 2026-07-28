# frozen_string_literal: true

# The horizontal bar: brand mark + icon-and-label links across the top. The
# app names the destinations; the bar only lays them out.
class Components::TopNav < Components::Base
  Entry = Data.define(:key, :label, :icon, :href)

  def initialize(entries:, active:, brand_icon: :plane)
    @entries = entries
    @active = active
    @brand_icon = brand_icon
  end

  def view_template
    nav(class: "flex items-center gap-1 border-b border-gray-200 px-6 md:px-12 h-14 sticky top-0 bg-white z-10") do
      div(class: "w-9 h-9 rounded-xl bg-(--app-primary) text-white flex items-center justify-center mr-4") do
        Icon(@brand_icon, size: 18)
      end
      @entries.each { |entry| link(entry) }
    end
  end

  private

  def link(entry)
    active = entry.key == @active
    a(href: entry.href, class: [
      "flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium",
      (active ? "bg-(--app-container) text-(--app-on-container)" : "text-gray-500 hover:bg-gray-100")
    ]) do
      Icon(entry.icon, size: 16)
      span { entry.label }
    end
  end
end
