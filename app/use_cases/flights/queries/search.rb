module Flights
  module Queries
    class Search
      IATA = /\A[A-Za-z]{3}\z/
      DATE = /\A\d{4}-\d{2}-\d{2}\z/

      # call(params) -> as_json-ready data
      # (params: origin, destination, departure_date, return_date)
      # log: optional callable(step_key, **data) narrating the search.
      # -> { best_flights: [...] } | { error:, details: }
      def call(params, log: nil)
        log&.call(:validate)
        invalid = invalid_params(params)
        if invalid.any?
          log&.call(:invalid, fields: invalid)
          return { error: "invalid_params", details: invalid }
        end

        GoogleFlights.search(
          origin: params[:origin].to_s.upcase,
          destination: params[:destination].to_s.upcase,
          departure_date: params[:departure_date].to_s,
          return_date: params[:return_date].to_s,
          log:
        )
      end

      private

      def invalid_params(params)
        {
          origin: IATA, destination: IATA,
          departure_date: DATE, return_date: DATE
        }.reject { |key, shape| params[key].to_s.match?(shape) }.keys
      end
    end
  end
end
