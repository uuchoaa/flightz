# frozen_string_literal: true

# A row of filter chips as links; the active chip links back to no filter.
# Chips arrive ready (key/label/active) — the bar only lays them out.
class Components::ChipBar < Components::Base
  Chip = Data.define(:key, :label, :active)

  def initialize(chips)
    @chips = chips
  end

  def view_template
    div(class: "flex flex-wrap gap-2 mb-6") do
      @chips.each do |chip|
        a(
          href: chip.active ? root_path : root_path(filter: chip.key),
          class: [
            "px-4 py-1.5 rounded-lg border text-sm",
            (chip.active ? "bg-(--app-primary) text-white border-(--app-primary)" : "border-gray-300 hover:bg-gray-50")
          ]
        ) { chip.label }
      end
    end
  end
end
