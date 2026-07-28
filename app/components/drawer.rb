# frozen_string_literal: true

# A right-hand slide-in panel + scrim, owned by a Stimulus controller
# (panel/scrim targets; scrim click closes). Content comes from the app.
class Components::Drawer < Components::Base
  def initialize(controller: "drawer")
    @controller = controller
  end

  def view_template(&)
    div(
      class: "hidden fixed inset-0 bg-black/20 z-30",
      data: { "#{@controller}_target": "scrim", action: "click->#{@controller}#close" }
    )
    aside(
      class: "fixed top-0 right-0 h-full w-[420px] max-w-full bg-white shadow-2xl z-40 " \
             "translate-x-full transition-transform duration-200 overflow-y-auto p-6",
      data: { "#{@controller}_target": "panel" },
      &
    )
  end
end
