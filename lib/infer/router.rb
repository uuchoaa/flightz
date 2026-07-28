module Infer
  # Cloud first for both modalities (picked by the benches); the local
  # Ollama sidecar is the fallback for everything. nil from a backend means
  # failure (schema-constrained calls always yield an object), so falling
  # back on nil is safe.
  class Router
    def initialize(text: Groq.new,
                   vision: Groq.new(model: ENV.fetch("GROQ_VISION_MODEL", "qwen/qwen3.6-27b")),
                   local: Ollama.new)
      @text = text
      @vision = vision
      @local = local
    end

    def structured(schema, prompt:, context: nil, images: nil)
      primary = images.present? ? @vision : @text
      primary.structured(schema, prompt:, context:, images:) ||
        @local.structured(schema, prompt:, context:, images:)
    end

    def ask(prompt)
      @text.ask(prompt) || @local.ask(prompt)
    end

    # Read-only description for the settings screen.
    def describe
      {
        text: @text.describe,
        vision: @vision.describe,
        fallback: @local.describe
      }
    end
  end
end
