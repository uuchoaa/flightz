require "test_helper"

class Flights::Queries::SearchTest < ActiveSupport::TestCase
  VALID = { origin: "cgh", destination: "JPA",
            departure_date: "2026-02-06", return_date: "2026-02-27" }.freeze

  test "answers with the backend's flights" do
    GoogleFlights.backend = GoogleFlights::Static.new(results: [ { best_flights: [ { price: 999.0 } ] } ])
    assert_equal 999.0, Flights::Queries::Search.new.call(VALID)[:best_flights].first[:price]
  end

  test "rejects malformed criteria as an error value" do
    answer = Flights::Queries::Search.new.call(VALID.merge(origin: "São Paulo", departure_date: "06/02"))
    assert_equal "invalid_params", answer[:error]
    assert_equal %i[origin departure_date], answer[:details]
  end

  test "degrades to the backend's error value when the seam is down" do
    GoogleFlights.backend = GoogleFlights::Static.new
    assert_equal "unavailable", Flights::Queries::Search.new.call(VALID)[:error]
  end
end
