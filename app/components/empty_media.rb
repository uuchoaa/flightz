# frozen_string_literal: true

# A media placeholder block: icon + caption, or the image itself.
class Components::EmptyMedia < Components::Base
  def initialize(icon:, caption: nil, image: nil)
    @icon = icon
    @caption = caption
    @image = image
  end

  def view_template
    div(
      class: "bg-(--app-surface) rounded-2xl h-36 mb-6 flex flex-col items-center " \
             "justify-center gap-2 text-gray-500 bg-cover bg-center",
      style: (@image ? "background-image: url('#{@image}')" : nil)
    ) do
      unless @image
        Icon(@icon, size: 24)
        span(class: "text-xs") { @caption } if @caption
      end
    end
  end
end
