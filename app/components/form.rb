# frozen_string_literal: true

# A form whose submit is ONE registry command: field names are the payload
# keys, `values` pre-fills by the same names, form_controller does the W.
#
#   Form("save_prefs", done: "salvo", values: page.prefs) do |f|
#     f.field :title, "Título"
#     f.field :format, "Formato", options: %w[a b]
#     f.submit "Salvar"
#   end
class Components::Form < Components::Base
  def initialize(command, done:, values: {}, inline: false)
    @command = command
    @done = done
    @values = values
    @inline = inline
  end

  def view_template
    form(
      class: (@inline ? "flex items-center gap-2 pt-3" : "flex flex-col gap-5"),
      data: { controller: "form", form_name_value: @command.to_s,
              form_done_value: @done, action: "submit->form#submit" }
    ) { yield(self) if block_given? }
  end

  def field(name, text = nil, type: :text, options: nil, placeholder: nil, required: false)
    value = @values[name.to_s]
    if options
      SelectInput(text, name:, options:, selected: value)
    else
      field_frame(text) do
        input(name:, type:, value:, placeholder:, required:, class: FIELD_CLASSES)
      end
    end
  end

  def submit(label = nil, icon: nil)
    if icon
      IconButton(icon, tone: :primary, submit: true)
    else
      button(
        type: "submit",
        class: "self-start bg-(--app-primary) text-white rounded-full px-8 py-2.5 " \
               "font-medium hover:bg-(--app-primary-strong)"
      ) { label }
    end
  end
end
