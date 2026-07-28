module Infer
  # Always "down": every caller takes its degrade path.
  class Null
    def structured(_schema, **)
      nil
    end

    def ask(_prompt)
      nil
    end
  end
end
