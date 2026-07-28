# frozen_string_literal: true

# A one-line natural-language prompt wired to a Stimulus controller that
# owns the round trip (input/button targets, timeout value). The app names
# the controller and every string.
class Components::PromptBar < Components::Base
  def initialize(controller:, placeholder:, submit:, hint: nil, timeout: nil, media_hint: nil, icon: :sparkle)
    @controller = controller
    @placeholder = placeholder
    @submit = submit
    @hint = hint
    @timeout = timeout
    @media_hint = media_hint
    @icon = icon
  end

  def view_template
    form(
      class: "flex items-center gap-3 bg-(--app-container) rounded-2xl px-5 py-2",
      data: { controller: @controller, "#{@controller}_timeout_value": @timeout,
              action: "submit->#{@controller}#submit" }
    ) do
      Icon(@icon, css: "text-(--app-primary) shrink-0")
      input(
        type: "text",
        placeholder: @placeholder,
        class: "flex-1 bg-transparent outline-none text-base py-2",
        data: { "#{@controller}_target": "input" }
      )
      IconButton(:camera, title: @media_hint, disabled: true) if @media_hint
      button(
        type: "submit",
        class: "bg-(--app-primary) text-white rounded-full px-6 py-2.5 font-medium " \
               "hover:bg-(--app-primary-strong) disabled:opacity-50 whitespace-nowrap",
        data: { "#{@controller}_target": "button" }
      ) { @submit }
    end
    p(class: "text-sm text-gray-500 mt-2 mb-6 ml-2") { @hint } if @hint
  end
end
