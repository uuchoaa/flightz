# frozen_string_literal: true

# The offers fragment, rendered on its own (no shell) so the stream
# controller can inject it once the search resolves.
class Views::FlightsResults < Components::Base
  def initialize(result:)
    @result = result
  end

  def view_template
    if @result[:error]
      Text(t("flights.error.#{@result[:error]}", default: t("flights.error.generic")), tone: :danger)
    else
      Table(rows: @result[:offers], empty: t("flights.empty")) do |tbl|
        tbl.col t("flights.col.flight"), :carrier, grow: true
        tbl.col t("flights.col.departure"), :departure
        tbl.col t("flights.col.arrival"), :arrival
        tbl.col t("flights.col.duration"), :duration, align: :end
        tbl.col(t("flights.col.stops")) { |offer| offer.stops }
        tbl.col t("flights.col.price"), :price, align: :end
      end
    end
  end
end
