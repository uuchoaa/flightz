# frozen_string_literal: true

# The V-shaped twin of Form: submit is a plain GET, field names become
# query params of the target path — for read screens driven by the URL.
#
#   QueryForm(root_path, values: page.criteria) do |f|
#     f.field :from, "De"
#     f.field :until, "Até", type: :date
#     f.submit "Buscar"
#   end
class Components::QueryForm < Components::Base
  def initialize(action, values: {})
    @action = action
    @values = values.transform_keys(&:to_s)
  end

  def view_template
    form(action: @action, method: "get", class: "flex flex-wrap items-end gap-4") do
      yield(self) if block_given?
    end
  end

  def field(name, text = nil, type: :text, placeholder: nil, required: false, width: nil)
    div(class: width == :narrow ? "w-28" : "w-40") do
      span(class: FIELD_LABEL_CLASSES) { text } if text
      # name as a String: a Symbol value gets underscore->dash mangled by
      # Phlex, which would break the query param keys (departure_date).
      input(name: name.to_s, type:, value: @values[name.to_s], placeholder:, required:, class: FIELD_CLASSES)
    end
  end

  def submit(label)
    button(
      type: "submit",
      class: "bg-(--app-primary) text-white rounded-full px-8 py-2.5 " \
             "font-medium hover:bg-(--app-primary-strong)"
    ) { label }
  end
end
