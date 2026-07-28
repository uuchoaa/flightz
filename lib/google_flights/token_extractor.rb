module GoogleFlights
  # Drives a real headless Chrome (Ferrum) through one Google Flights
  # search and reads the tokens off the GetShoppingResults request the
  # page itself makes. Returns nil on any failure — callers degrade.
  class TokenExtractor
    SEARCH_URL = "https://www.google.com/travel/flights?q=flights%20from%20CGH%20to%20REC&hl=pt-BR&curr=BRL"
    ENDPOINT_MARKER = "GetShoppingResults"

    def initialize(timeout: 45)
      @timeout = timeout
    end

    def extract(log: nil)
      log&.call(:browser_launch)
      browser = Ferrum::Browser.new(headless: true, timeout: @timeout, process_timeout: @timeout,
                                    window_size: [ 1366, 768 ])
      log&.call(:browser_navigate)
      browser.goto(SEARCH_URL)
      log&.call(:browser_wait_request)
      exchange = wait_for_exchange(browser)
      tokens = exchange && tokens_from(exchange.request)
      log&.call(tokens ? :browser_extracted : :browser_no_tokens)
      tokens
    rescue StandardError => e
      log&.call(:browser_error, message: e.message)
      nil
    ensure
      browser&.quit rescue nil
    end

    private

    def wait_for_exchange(browser)
      deadline = Time.now + @timeout
      loop do
        exchange = browser.network.traffic.find { |ex| ex.request&.url&.include?(ENDPOINT_MARKER) }
        return exchange if exchange
        return nil if Time.now > deadline

        sleep 0.5
      end
    end

    def tokens_from(request)
      headers = request.headers.transform_keys { |key| key.split("-").map(&:capitalize).join("-") }
      query = URI.decode_www_form(URI.parse(request.url).query.to_s).to_h

      tokens = {
        "X-Goog-BatchExecute-Bgr" => headers["X-Goog-Batchexecute-Bgr"],
        "X-Goog-Ext-259736195-Jspb" => headers["X-Goog-Ext-259736195-Jspb"],
        "X-Browser-Validation" => headers["X-Browser-Validation"],
        "f.sid" => query["f.sid"],
        "bl" => query["bl"]
      }.compact
      tokens.size == 5 ? tokens : nil
    end
  end
end
