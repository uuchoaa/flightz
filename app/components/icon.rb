# frozen_string_literal: true

# Hand-drawn 24px stroke icons (lucide-style): enough for this UI without
# shipping an icon font. Fill-style icons carry filled: true.
class Components::Icon < Components::Base
  SHAPES = {
    search: { paths: [ "m21 21-4.5-4.5" ], circles: [ [ 11, 11, 7 ] ] },
    sparkle: { paths: [ "M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z" ], filled: true },
    camera: { paths: [ "M4 8h3l2-3h6l2 3h3v12H4V8z" ], circles: [ [ 12, 13.5, 3.5 ] ] },
    plus: { paths: [ "M12 5v14", "M5 12h14" ] },
    close: { paths: [ "M6 6l12 12", "M18 6L6 18" ] },
    trash: { paths: [ "M4 7h16", "M9 7V4h6v3", "M6 7l1 14h10l1-14" ] },
    pencil: { paths: [ "M4 20l1-4L17 4l3 3L8 19l-4 1z" ] },
    check: { paths: [ "M5 13l4 4L19 7" ] },
    drop: { paths: [ "M12 3s6 7 6 11a6 6 0 1 1-12 0c0-4 6-11 6-11z" ] },
    wrench: { paths: [ "M21 7a5 5 0 0 1-7 5l-7 7a2.1 2.1 0 0 1-3-3l7-7a5 5 0 0 1 6.6-6.4L14 6l4 4 2.4-2.4c.4.9.6 1.6.6 2.4z" ] },
    box: { paths: [ "M3 8V6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2", "M3 8h18v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8", "M10 12h4" ] },
    receipt: { paths: [ "M6 3h12v18l-2-1.5L14 21l-2-1.5L10 21l-2-1.5L6 21V3z", "M9 8h6", "M9 12h6" ] },
    tune: { paths: [ "M4 7h8", "M16 7h4", "M4 17h4", "M12 17h8" ], circles: [ [ 14, 7, 2 ], [ 10, 17, 2 ] ] },
    indent: { paths: [ "M7 5v6a2 2 0 0 0 2 2h8", "M14 10l3 3-3 3" ] },
    plane: { paths: [ "M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z" ] }
  }.freeze

  def initialize(name, size: 20, css: "")
    @shape = SHAPES.fetch(name)
    @size = size
    @css = css
  end

  def view_template
    filled = @shape[:filled]
    svg(
      viewBox: "0 0 24 24", width: @size, height: @size, class: @css,
      fill: filled ? "currentColor" : "none",
      stroke: filled ? "none" : "currentColor",
      stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round"
    ) do |s|
      @shape[:paths]&.each { |d| s.path(d:) }
      @shape[:circles]&.each { |cx, cy, r| s.circle(cx:, cy:, r:) }
    end
  end
end
