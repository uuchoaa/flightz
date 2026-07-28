require "net/http"
require "json"

module Infer
  class Ollama
    def initialize(model: ENV.fetch("INFER_MODEL", "gemma3:4b"),
                   vision_model: ENV["INFER_VISION_MODEL"],
                   url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"))
      @model = model
      @vision_model = vision_model || model
      @uri = URI("#{url}/api/chat")
    end

    # JSON-schema-constrained decoding; nil on any failure (down, timeout,
    # unparseable output).
    def structured(schema, prompt:, context: nil, images: nil)
      message = { role: "user", content: content_for(prompt, context) }
      message[:images] = Array(images) if images.present?
      body = { model: images.present? ? @vision_model : @model,
               messages: [ message ], stream: false, format: schema,
               options: { temperature: Float(ENV.fetch("INFER_TEMPERATURE", "0")),
                          seed: Integer(ENV.fetch("INFER_SEED", "42")) },
               keep_alive: ENV.fetch("INFER_KEEP_ALIVE", "30m") }
      response = post(body) or return nil
      JSON.parse(response.dig("message", "content"), symbolize_names: true)
    rescue JSON::ParserError, TypeError
      nil
    end

    def ask(prompt)
      response = post(model: @model, messages: [ { role: "user", content: prompt } ],
                      stream: false, keep_alive: ENV.fetch("INFER_KEEP_ALIVE", "30m"))
      response&.dig("message", "content")
    end

    def describe
      { backend: "ollama", model: @model, vision_model: @vision_model, url: @uri.origin }
    end

    private

    def content_for(prompt, context)
      context ? "#{prompt}\n\nContext:\n#{context.to_json}" : prompt
    end

    def post(body)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.open_timeout = 3
      http.read_timeout = Integer(ENV.fetch("INFER_TIMEOUT", "180"))
      response = http.post(@uri.path, body.to_json, "Content-Type" => "application/json")
      response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
    rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, IOError, SocketError
      nil
    end
  end
end
