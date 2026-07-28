require "net/http"
require "json"

module Infer
  # Cloud backend: Groq's OpenAI-compatible API with strict structured
  # outputs (gpt-oss models) — the same hard grammar guarantee as the
  # local Ollama format. Text-only; images resolve to nil so callers keep
  # their degrade path (vision stays on the local sidecar).
  class Groq
    URL = URI("https://api.groq.com/openai/v1/chat/completions")

    def initialize(model: ENV.fetch("GROQ_MODEL", "openai/gpt-oss-20b"),
                   api_key: ENV["GROQ_API_KEY"])
      @model = model
      @api_key = api_key
    end

    # gpt-oss models take the schema as a strict decoding grammar (text
    # only); the rest get JSON Object Mode with the schema spelled out in
    # the prompt — weaker guarantee, which the registry/domain defenses
    # already absorb. Images ride the OpenAI-compatible content parts.
    def structured(schema, prompt:, context: nil, images: nil)
      return nil if @api_key.blank?

      text = content_for(prompt, context)
      body = { model: @model, temperature: 0 }
      if strict?
        return nil if images.present?

        body[:reasoning_effort] = ENV.fetch("GROQ_REASONING", "low")
        body[:response_format] = {
          type: "json_schema",
          json_schema: { name: "commands", strict: true, schema: schema }
        }
      else
        body[:response_format] = { type: "json_object" }
        text += "\n\nRespond with JSON only, matching this JSON Schema exactly:\n#{schema.to_json}"
      end
      body[:messages] = [ message_with(text, images) ]
      response = post(body) or return nil
      JSON.parse(response.dig("choices", 0, "message", "content"), symbolize_names: true)
    rescue JSON::ParserError, TypeError
      nil
    end

    def ask(prompt)
      return nil if @api_key.blank?

      response = post(model: @model, messages: [ { role: "user", content: prompt } ])
      response&.dig("choices", 0, "message", "content")
    end

    def describe
      { backend: "groq", model: @model, available: @api_key.present? }
    end

    private

    def strict?
      @model.include?("gpt-oss")
    end

    def message_with(text, images)
      return { role: "user", content: text } if images.blank?

      parts = [ { type: "text", text: text } ]
      parts += Array(images).map do |b64|
        { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{b64}" } }
      end
      { role: "user", content: parts }
    end

    def content_for(prompt, context)
      context ? "#{prompt}\n\nContext:\n#{context.to_json}" : prompt
    end

    def post(body)
      http = Net::HTTP.new(URL.host, URL.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = Integer(ENV.fetch("INFER_TIMEOUT", "60"))
      response = http.post(URL.path, body.to_json,
                           "Content-Type" => "application/json",
                           "Authorization" => "Bearer #{@api_key}")
      response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
    rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, IOError, SocketError, OpenSSL::SSL::SSLError
      nil
    end
  end
end
