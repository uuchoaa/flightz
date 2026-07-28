module GoogleFlights
  # Builds the f.req form body for GetShoppingResults: a JSON envelope
  # whose second element is itself a stringified JSON array of positional
  # search parameters (reverse-engineered from a captured HAR).
  module Payload
    AIRPORT_TYPE = 0 # specific airport (CGH, GRU)
    CITY_TYPE    = 4 # city/metro area (/m/022pfm)

    module_function

    def build(origin:, destination:, departure_date:, return_date:)
      params = [
        [],
        [
          nil, nil, 1, nil, [], 1, [ 1, 0, 0, 0 ],
          nil, nil, nil, nil, nil, nil,
          [
            leg(origin, destination, departure_date),
            leg(destination, origin, return_date)
          ],
          nil, nil, nil, 1
        ],
        0, 0, 0, 1
      ]
      "f.req=#{URI.encode_www_form_component([ nil, params.to_json ].to_json)}&"
    end

    def leg(from, to, date)
      [
        [ [ [ from.to_s.upcase, AIRPORT_TYPE ] ] ],
        [ [ [ to.to_s.upcase, AIRPORT_TYPE ] ] ],
        nil, 0, nil, nil, date,
        nil, nil, nil, nil, nil, nil, nil, 3
      ]
    end
  end
end
