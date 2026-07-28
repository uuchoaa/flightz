# frozen_string_literal: true

# Declarative table: the caller describes columns (a LAYOUT spec, never
# domain data), the Table lays them out. A cell is a presenter method name
# (Symbol) or a block; either may return text or a component.
#
#   Table(rows: page.rows, empty: "Nada.") do |t|
#     t.col "Nome",  :name, grow: true
#     t.col "Valor", :value,    align: :end
#     t.col("Status") { |e| Badge(e.status) }
#   end
class Components::Table < Components::Base
  Column = Data.define(:header, :cell, :align, :grow, :truncate, :muted)

  def initialize(rows:, row_action: nil, row_data: nil, empty: nil)
    @rows = rows
    @row_action = row_action # Stimulus action fired on row click
    @row_data = row_data     # row entry -> extra data attrs (search text, payload)
    @empty = empty
    @columns = []
  end

  def col(header, cell = nil, align: nil, grow: false, truncate: false, muted: false, &block)
    @columns << Column.new(header:, cell: cell || block, align:, grow:, truncate:, muted:)
  end

  def view_template
    # The content block only collects column specs (col emits no markup).
    yield(self) if block_given?

    table(class: "w-full text-left") do
      thead do
        tr(class: "text-xs text-gray-500 tracking-widest uppercase border-b border-gray-200") do
          @columns.each { |column| th(class: tw("py-3 px-3 font-medium", head_class(column))) { column.header } }
        end
      end
      tbody do
        @rows.each { |entry| row(entry) }
        empty_row if @rows.empty?
      end
    end
  end

  private

  def row(entry)
    attrs = { class: "border-b border-gray-100 hover:bg-gray-50" }
    data = @row_data ? @row_data.call(entry) : {}
    data[:action] = "click->#{@row_action}" if @row_action
    attrs[:class] += " cursor-pointer" if @row_action
    attrs[:data] = data unless data.empty?

    tr(**attrs) do
      @columns.each do |column|
        td(class: tw("py-3 px-3", cell_class(column))) { cell(entry, column.cell) }
      end
    end
  end

  # A block cell runs as a closure in its author's context (the screen), so
  # it sees the screen's private helpers; Phlex shares the output buffer.
  def cell(entry, spec)
    value = spec.is_a?(Symbol) ? entry.public_send(spec) : spec.call(entry)
    case value
    when Phlex::HTML then render(value)
    when nil then nil
    else plain(value.to_s)
    end
  end

  def head_class(column)
    column.align == :end ? "text-right" : nil
  end

  def cell_class(column)
    [
      (column.align == :end ? "text-right" : nil),
      (column.grow ? "w-full" : "whitespace-nowrap"),
      (column.truncate ? "truncate max-w-md" : nil),
      (column.muted ? "text-gray-500" : nil)
    ].compact.join(" ").presence
  end

  def tw(*classes)
    classes.compact.join(" ")
  end

  def empty_row
    tr { td(colspan: @columns.size, class: "py-12 text-center text-gray-500") { @empty } } if @empty
  end
end
