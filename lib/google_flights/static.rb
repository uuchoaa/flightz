module GoogleFlights
  # Test backend: replays canned results in order; empty means "down",
  # which exercises the degrade paths.
  class Static
    def initialize(results: nil)
      @results = Array(results)
    end

    def search(log: nil, **)
      log&.call(:backend_static)
      @results.shift || { error: "unavailable" }
    end
  end
end
