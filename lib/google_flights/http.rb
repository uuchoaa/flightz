require "net/http"
require "zlib"
require "stringio"

module GoogleFlights
  # The real backend: POSTs to FlightsFrontendService mimicking the browser
  # request captured in a HAR, with live tokens from the token store.
  # Gzip only on Accept-Encoding — no brotli dependency.
  class Http
    ENDPOINT = "https://www.google.com/_/FlightsFrontendUi/data/travel.frontend.flights.FlightsFrontendService/GetShoppingResults"

    def initialize(tokens: Tokens.new)
      @tokens = tokens
    end

    def search(origin:, destination:, departure_date:, return_date:, log: nil)
      log&.call(:tokens_resolve)
      tokens = @tokens.fetch(log:)
      log&.call(:payload_build, route: "#{origin}-#{destination}")
      uri = URI.parse("#{ENDPOINT}?#{query_params(tokens)}")
      request = build_request(uri, tokens)
      request.body = Payload.build(origin:, destination:, departure_date:, return_date:)

      log&.call(:http_send, host: uri.hostname)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) do |http|
        http.request(request)
      end
      log&.call(:http_response, code: response.code, bytes: response.body&.bytesize)

      case response
      when Net::HTTPSuccess
        body = decode(response, log:)
        Parser.parse(body, log:)
      else
        log&.call(:http_error, code: response.code)
        { error: "http", details: "#{response.code} #{response.message}" }
      end
    rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError, SocketError => e
      log&.call(:network_error, message: e.message)
      { error: "network", details: e.message }
    end

    private

    def query_params(tokens)
      URI.encode_www_form(
        "f.sid" => tokens["f.sid"], "bl" => tokens["bl"],
        "hl" => "pt-BR", "soc-app" => 162, "soc-platform" => 1, "soc-device" => 1,
        "_reqid" => rand(10_000..99_999), "rt" => "c"
      )
    end

    def build_request(uri, tokens)
      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "*/*"
      request["Accept-Encoding"] = "gzip"
      request["Accept-Language"] = "pt-BR,pt;q=0.9"
      request["Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
      request["Origin"] = "https://www.google.com"
      request["Referer"] = "https://www.google.com/travel/flights"
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                              "(KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
      request["X-Same-Domain"] = "1"
      Tokens::HEADER_KEYS.each { |key| request[key] = tokens[key] }
      request
    end

    def decode(response, log: nil)
      body = response.body
      return body unless response["content-encoding"] == "gzip"

      log&.call(:decode_gzip)
      Zlib::GzipReader.new(StringIO.new(body)).read
    end
  end
end
