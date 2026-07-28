# frozen_string_literal: true

# Wraps one parsed flight (a lib/google_flights hash) for the search table.
class FlightPresenter
  include Components::Labels

  attr_reader :raw

  def initialize(raw)
    @raw = raw
  end

  def carrier
    [ raw[:airline], raw[:flight_number] ].compact.join(" ")
  end

  def departure = leg_time(raw[:departure_time])
  def arrival = leg_time(raw[:arrival_time])

  def duration
    hours, minutes = raw[:duration].to_i.divmod(60)
    format("%dh%02d", hours, minutes)
  end

  def stops
    count = raw[:stops].to_i
    label = I18n.t("flights.stops", count:)
    Components::Badge.new(label, tone: count.zero? ? :good : :neutral)
  end

  def price
    brl((raw[:price].to_f * 100).round)
  end

  private

  def leg_time(iso)
    return "" if iso.nil?

    I18n.l(Time.iso8601(iso), format: :short)
  end
end
