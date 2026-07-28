require "test_helper"

class GoogleFlights::PayloadTest < ActiveSupport::TestCase
  test "wraps both legs in the f.req envelope" do
    body = GoogleFlights::Payload.build(
      origin: "cgh", destination: "jpa",
      departure_date: "2026-02-06", return_date: "2026-02-27"
    )
    assert body.start_with?("f.req=")
    assert body.end_with?("&")

    outer = JSON.parse(URI.decode_www_form_component(body.delete_prefix("f.req=").delete_suffix("&")))
    assert_nil outer[0]
    legs = JSON.parse(outer[1])[1][13]
    assert_equal [ [ [ [ "CGH", 0 ] ] ], [ [ [ "JPA", 0 ] ] ] ], legs[0][0..1]
    assert_equal "2026-02-06", legs[0][6]
    assert_equal [ [ [ [ "JPA", 0 ] ] ], [ [ [ "CGH", 0 ] ] ] ], legs[1][0..1]
    assert_equal "2026-02-27", legs[1][6]
  end
end
