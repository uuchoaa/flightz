module Infer
  # Test backend: replays canned responses in order; empty means "down",
  # which exercises the degrade paths.
  class Static
    def initialize(structured: nil, ask: nil)
      @structured = Array(structured)
      @ask = Array(ask)
    end

    def structured(_schema, **)
      @structured.shift
    end

    def ask(_prompt)
      @ask.shift
    end
  end
end
