module GoogleFlights
  # Decodes the GetShoppingResults wire format: an anti-JSON prefix, then
  # length-prefixed JSON chunks; the largest chunk carries the shopping
  # payload, whose element [0][2] is a stringified JSON with the flight
  # lists. Positional indexes are reverse-engineered (docs/architecture.md).
  module Parser
    module_function

    # Raw HTTP body -> { best_flights: [...] } | { error:, details: }
    def parse(body, log: nil)
      log&.call(:parse_envelope)
      envelope = envelope(body)
      return { error: "parse", details: "no JSON payload in response" } unless envelope

      result = extract(envelope)
      log&.call(:parse_done, count: result[:best_flights].size)
      result
    rescue JSON::ParserError => e
      log&.call(:parse_error, message: e.message)
      { error: "parse", details: e.message }
    end

    # The outer envelope, already JSON-parsed -> { best_flights: [...] }
    def extract(envelope)
      inner = envelope && envelope.dig(0, 2)
      return { best_flights: [] } unless inner

      sections = JSON.parse(inner)
      # Google nests the itinerary lists at route-dependent depths (best at
      # section 2, the rest at 3; each entry wrapped differently per query).
      # Instead of guessing indexes, walk the tree and collect every priced
      # flight-info node — the one shape that survives every route. Pre-order
      # keeps Google's ranking; dedup drops the best-list/full-list overlap.
      flights = collect_infos(sections).map { |info| flight_from_info(info) }
      { best_flights: dedup(flights) }
    end

    def envelope(body)
      clean = body.sub(/\A\)\]\}'\n\n/, "")
      chunks = clean.each_line.filter_map do |line|
        line = line.strip
        next if line.empty? || line.match?(/\A\d+\z/)

        begin
          JSON.parse(line)
        rescue JSON::ParserError
          nil
        end
      end
      chunks.max_by { |chunk| chunk.to_s.length }
    end

    # Pre-order walk collecting every flight-info node. The signature — IATA
    # endpoints, an integer duration, and a cents price at [22][7] — is worn
    # only by itineraries; segments carry airports but no price, so they
    # never match and recursion never double-counts.
    def collect_infos(node, acc = [])
      return acc unless node.is_a?(Array)

      acc << node if flight_info?(node)
      node.each { |child| collect_infos(child, acc) }
      acc
    end

    def flight_info?(node)
      node[3].is_a?(String) && node[3].match?(/\A[A-Z]{3}\z/) &&
        node[6].is_a?(String) && node[6].match?(/\A[A-Z]{3}\z/) &&
        node[9].is_a?(Integer) &&
        node[22].is_a?(Array) && node[22][7].is_a?(Integer) && node[22][7] > 0
    end

    def dedup(flights)
      flights.uniq { |f| [ f[:airline_code], f[:flight_number], f[:departure_time], f[:price] ] }
    end

    def flight_from_info(info)
      segments = info[2].is_a?(Array) ? info[2] : []
      price_cents = info[22][7]

      {
        departure_airport: { code: info[3], name: airport_name(segments[0], info[3]) },
        arrival_airport: { code: info[6], name: airport_name(segments[0], info[6]) },
        duration: info[9],
        airplane: segments.dig(0, 17),
        airline: info.dig(1, 0),
        airline_code: info[0],
        flight_number: flight_number(segments[0]),
        extensions: extensions(segments[0]),
        emissions: emissions(segments[0]),
        price: (price_cents / 100.0).round(2),
        departure_time: datetime(info[4], info[5]),
        arrival_time: datetime(info[7], info[8]),
        stops: info[10] || 0,
        segments: segments.filter_map { |segment| segment_summary(segment) }
      }
    end

    def airport_name(segment, code)
      segment&.dig(4) || segment&.dig(5) || code
    end

    def flight_number(segment)
      code = segment&.dig(22)
      code && "#{code[0]}#{code[1]}"
    end

    def extensions(segment)
      return [] unless segment

      amenities = segment[11] || []
      list = []
      list << "In-seat power & USB outlets" if amenities[1]
      list << "Wi-Fi" if amenities[10]
      list << "Average legroom (#{segment[13]})" if segment[13]
      list
    end

    def emissions(segment)
      grams = segment&.dig(29)
      return nil unless grams

      { this_flight: grams, typical_for_this_route: grams, difference_percent: 0 }
    end

    def segment_summary(segment)
      return nil unless segment

      {
        departure_airport: segment[3],
        arrival_airport: segment[6],
        departure_time: datetime(segment[19], segment[8]),
        arrival_time: datetime(segment[20], segment[10]),
        duration: segment[11],
        airline: segment.dig(22, 3),
        flight_number: flight_number(segment),
        airplane: segment[16]
      }
    end

    # Dates come as [y, m, d]; times as [hour, minute], bare hour, or nil.
    def datetime(date, time)
      return nil unless date.is_a?(Array) && date.length >= 3 && date[0..2].all?

      hour, minute = time.is_a?(Array) ? [ time[0] || 0, time[1] || 0 ] : [ time.is_a?(Integer) ? time : 0, 0 ]
      format("%04d-%02d-%02dT%02d:%02d:00-03:00", date[0], date[1], date[2], hour, minute)
    end
  end
end
