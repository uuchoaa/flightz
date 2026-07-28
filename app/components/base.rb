# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T

  # The wiring sugar: one call bakes the data-attribute contract the
  # generic command_controller reads. Payload keys ARE the command's
  # PAYLOAD keys; `prompt:` switches to the prompt-driven variant.
  # Returns a plain attrs hash the kit accepts through `on:` — the app
  # never splats it.
  #
  #   IconButton(:archive, on: wire("archive_record", record_id: 3,
  #                                 done: "arquivado"))
  def wire(command, done: nil, confirm: nil, prompt: nil, prompt_key: nil, prompt_default: nil, **payload)
    data = {
      action: prompt ? "command#promptRun" : "command#run",
      name: command.to_s,
      payload: payload.to_json
    }
    data[:done] = done if done
    data[:confirm] = confirm if confirm
    data[:prompt_label] = prompt if prompt
    data[:prompt_key] = prompt_key if prompt_key
    data[:prompt_default] = prompt_default if prompt_default
    data
  end

  private

  # Normalizes the `on:` contract every actionable kit member takes:
  # a plain Stimulus action string ("drawer#add") or a wire(...) hash.
  def on_data(on)
    return {} if on.nil?

    on.is_a?(Hash) ? on : { action: on }
  end

  # "controller.name" -> { controller_target: "name" } — the target
  # contract inputs and buttons take (`target: "drawer.name"`).
  def target_data(target)
    return {} if target.nil?

    controller, name = target.split(".", 2)
    { "#{controller}_target": name }
  end

  # The house field look, shared by every input member of the kit.
  FIELD_CLASSES = "w-full border-b border-gray-300 focus:border-(--app-primary) " \
                  "outline-none py-1.5 bg-transparent"
  FIELD_LABEL_CLASSES = "block text-sm text-(--app-primary) mb-1"

  def field_frame(label)
    div(class: "w-full") do
      span(class: FIELD_LABEL_CLASSES) { label } if label
      yield
    end
  end
end
