# frozen_string_literal: true

# Round avatar (image or icon) + title + subtitle — the leading cell of a
# rich list row.
class Components::Identity < Components::Base
  def initialize(title:, subtitle: nil, image: nil, icon: :box)
    @title = title
    @subtitle = subtitle
    @image = image
    @icon = icon
  end

  def view_template
    div(class: "flex items-center gap-4") do
      div(class: "w-11 h-11 rounded-full bg-(--app-container) text-(--app-on-container) " \
                 "flex items-center justify-center shrink-0 overflow-hidden") do
        if @image
          img(src: @image, alt: @title, class: "w-full h-full object-cover")
        else
          Icon(@icon, size: 18)
        end
      end
      div(class: "min-w-0") do
        p(class: "font-semibold truncate") { @title }
        p(class: "text-sm text-gray-500 truncate") { @subtitle } if @subtitle
      end
    end
  end
end
