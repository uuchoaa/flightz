require "test_helper"

# Ported from the original flights-api parser suite: the captured envelope
# fixture must keep yielding well-formed flights.
class GoogleFlights::ParserTest < ActiveSupport::TestCase
  ENVELOPE = JSON.parse(File.read(Rails.root.join("test/fixtures/files/google_flights/shopping_results_envelope.json")))

  setup do
    @flights = GoogleFlights::Parser.extract(ENVELOPE)[:best_flights]
  end

  test "extracts multiple flights" do
    assert_operator @flights.length, :>=, 2
  end

  test "flight has the contract fields" do
    %i[departure_airport arrival_airport duration airplane airline airline_code
       flight_number extensions emissions price departure_time arrival_time
       stops segments].each do |field|
      assert @flights.first.key?(field), "missing #{field}"
    end
  end

  test "airports carry code and name" do
    @flights.first.values_at(:departure_airport, :arrival_airport).each do |airport|
      assert_kind_of String, airport[:code]
      assert_kind_of String, airport[:name]
      assert_match(/\A[A-Z]{3}\z/, airport[:code])
    end
  end

  test "price is reais, not cents" do
    prices = @flights.map { |flight| flight[:price] }
    prices.each { |price| assert_kind_of Numeric, price }
    prices.each { |price| assert_operator price, :>, 0 }
    prices.each { |price| assert_operator price, :<, 100_000 }
    assert_operator prices.uniq.length, :>, 1
  end

  test "duration and stops are sane integers" do
    @flights.each do |flight|
      assert_operator flight[:duration], :>, 0
      assert_operator flight[:stops], :>=, 0
    end
  end

  test "airline fields are present and valid" do
    @flights.each do |flight|
      assert_match(/\A[A-Z0-9]{2,}\z/, flight[:airline_code])
      assert flight[:airline].present?
    end
  end

  test "times are ISO 8601" do
    iso = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00\z/
    @flights.each do |flight|
      assert_match(iso, flight[:departure_time]) if flight[:departure_time]
      assert_match(iso, flight[:arrival_time]) if flight[:arrival_time]
    end
  end

  test "segments carry the leg contract" do
    segment = @flights.first[:segments].first
    %i[departure_airport arrival_airport duration airline flight_number].each do |field|
      assert segment.key?(field), "missing #{field}"
    end
  end

  test "degrades to empty on nil or foreign input" do
    assert_equal({ best_flights: [] }, GoogleFlights::Parser.extract(nil))
    assert_equal({ best_flights: [] }, GoogleFlights::Parser.extract([]))
  end

  test "parse handles the wire format prefix and chunking" do
    body = ")]}'\n\n123\n#{ENVELOPE.to_json}\n"
    assert_operator GoogleFlights::Parser.parse(body)[:best_flights].length, :>=, 2
  end

  test "parse returns an error value on garbage" do
    assert_equal "parse", GoogleFlights::Parser.parse("not json at all")[:error]
  end
end
