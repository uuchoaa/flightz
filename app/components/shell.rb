# frozen_string_literal: true

# The page frame: top nav + #page content + snackbar. `aside` renders
# outside #page so refreshPage never swaps an open panel away.
class Components::Shell < Components::Base
  def initialize(nav:, active:, controllers:, aside: nil)
    @nav = nav
    @active = active
    @controllers = controllers
    @aside = aside
  end

  def view_template(&)
    div(class: "min-h-screen text-gray-900", data: { controller: @controllers.join(" ") }) do
      TopNav(entries: @nav, active: @active)
      main(class: "px-6 md:px-12 py-6 max-w-[1400px] mx-auto") do
        div(id: "page", &)
      end
      render @aside if @aside
      Toast()
    end
  end
end
