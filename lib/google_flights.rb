# Thin seam over Google Flights' private shopping endpoint. One consumer:
# the flights search query. Backends are swappable; every failure mode
# resolves to an error value, never an exception.
module GoogleFlights
  class << self
    attr_writer :backend

    def backend
      @backend ||= Http.new
    end

    # -> { best_flights: [...] } | { error:, details: }
    # log: optional callable(step_key, **data) narrating each pipeline step.
    def search(origin:, destination:, departure_date:, return_date:, log: nil)
      backend.search(origin:, destination:, departure_date:, return_date:, log:)
    end
  end
end
