require "test_helper"

class ScreensTest < ActionDispatch::IntegrationTest
  CRITERIA = { origin: "CGH", destination: "JPA",
               departure_date: "2026-02-06", return_date: "2026-02-27" }.freeze

  OFFER = { departure_airport: { code: "CGH", name: "Congonhas" },
            arrival_airport: { code: "JPA", name: "Castro Pinto" },
            duration: 190, airline: "LATAM", airline_code: "LA",
            flight_number: "LA4646", price: 1234.56, stops: 0,
            departure_time: "2026-02-06T09:00:00-03:00",
            arrival_time: "2026-02-06T12:10:00-03:00", segments: [] }.freeze

  test "flights screen renders instantly with the form and console" do
    get root_path
    assert_response :success
    assert_select "form[action=?]", root_path
    assert_select "[data-controller~=stream]"
  end

  test "the stream narrates steps and injects the offers" do
    GoogleFlights.backend = GoogleFlights::Static.new(results: [ { best_flights: [ OFFER ] } ])
    get flights_stream_path, params: CRITERIA
    assert_response :success
    assert_equal "text/event-stream", response.media_type
    assert_match "event: step", response.body
    assert_match I18n.t("flights.step.validate"), response.body
    assert_match "event: done", response.body
    assert_match "LA4646", response.body
  end

  test "a search lands a row in the logs ledger" do
    GoogleFlights.backend = GoogleFlights::Static.new(results: [ { best_flights: [ OFFER ] } ])
    assert_difference -> { Command.where(name: "search").count }, 1 do
      get flights_stream_path, params: CRITERIA
    end
    row = Command.where(name: "search").order(:id).last
    assert_equal "done", row.status
    assert_equal "JPA", row.payload["destination"]
    assert_equal 1, row.result.dig("ok", "count")
  end

  test "the stream surfaces the error value" do
    GoogleFlights.backend = GoogleFlights::Static.new
    get flights_stream_path, params: CRITERIA
    assert_response :success
    assert_match "event: done", response.body
    assert_match I18n.t("flights.error.unavailable"), response.body
  end

  test "flights search answers as JSON through the queries API" do
    GoogleFlights.backend = GoogleFlights::Static.new(results: [ { best_flights: [ OFFER ] } ])
    get api_query_path("flights_search"), params: CRITERIA
    assert_response :success
    assert_equal "LA4646", response.parsed_body["best_flights"].first["flight_number"]
  end

  test "logs renders" do
    get app_logs_path
    assert_response :success
  end

  test "settings renders" do
    get app_settings_path
    assert_response :success
  end
end
