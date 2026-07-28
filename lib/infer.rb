# Thin seam over a local LLM. Two consumers: generators at generation time,
# the capture use case at runtime. Backends are swappable; every failure mode
# resolves to nil so callers degrade to values, never exceptions.
module Infer
  class << self
    attr_writer :backend

    def backend
      @backend ||= Router.new
    end

    def structured(schema, prompt:, context: nil, images: nil)
      backend.structured(schema, prompt:, context:, images:)
    end

    def ask(prompt)
      backend.ask(prompt)
    end
  end
end
