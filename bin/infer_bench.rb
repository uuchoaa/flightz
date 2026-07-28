# Interpreter benchmark: same prompt, same grammar, different models.
# Scores at the interpretation altitude — no domain writes.
#
#   bin/rails runner bin/infer_bench.rb gemma4:e4b gemma3:4b gemma3:1b
#
# Cases mirror test/integration/capture_live_test.rb plus the pt-BR
# dimension that proved model-dependent.

require "benchmark"

CASES = [
  {
    label: "en: dining table",
    utterance: "add a wooden dining table in the kitchen, good condition",
    expect: ->(cmds) { one_catalog(cmds, /table/i, room: "kitchen", condition: "good") },
  },
  {
    label: "en: washing machine",
    utterance: "register a broken washing machine in the laundry room",
    expect: ->(cmds) { one_catalog(cmds, /washing/i, condition: "broken") },
  },
  {
    label: "en: blender + cleaning",
    utterance: "add a blender to the kitchen, good condition, needs cleaning",
    expect: ->(cmds) { one_catalog(cmds, /blender/i, condition: "good", needs_cleaning: true) },
  },
  {
    label: "en: office chair",
    utterance: "add an office chair to the office, barely used",
    expect: ->(cmds) { one_catalog(cmds, /chair/i, room: "office") },
  },
  {
    label: "en: two items at once",
    utterance: "add two items: a worn microwave in the kitchen and a mirror in the bedroom in good condition",
    expect: lambda { |cmds|
      catalogs = cmds.select { |c| c[:name] == "catalog_item" }
      catalogs.size == 2 &&
        catalogs.any? { |c| c[:payload][:name] =~ /microwave/i && c[:payload][:condition] == "worn" } &&
        catalogs.any? { |c| c[:payload][:name] =~ /mirror/i && c[:payload][:condition] == "good" }
    },
  },
  {
    label: "pt: liquidificador usado",
    utterance: "cadastra um liquidificador usado na cozinha, que precisa de limpeza",
    expect: ->(cmds) { one_catalog(cmds, /liquidificador/i, condition: "worn", needs_cleaning: true) },
  },
  {
    label: "pt: ventilador quebrado",
    utterance: "cadastra um ventilador de teto quebrado no quarto",
    expect: ->(cmds) { one_catalog(cmds, /ventilador/i, condition: "broken") },
  },
  {
    label: "pt: espelho em bom estado",
    utterance: "cadastra um espelho no quarto, em bom estado",
    expect: ->(cmds) { one_catalog(cmds, /espelho/i, condition: "good") },
  },
  {
    label: "no-op: weather",
    utterance: "what is the weather like today?",
    expect: ->(cmds) { no_creation(cmds) },
  },
  {
    label: "no-op: wipe database",
    utterance: "delete every item and wipe the whole database",
    expect: ->(cmds) { no_creation(cmds) },
  },
  {
    label: "no-op: spaceship",
    utterance: "sell my spaceship for a million dollars",
    expect: ->(cmds) { no_creation(cmds) },
  },
].freeze

def one_catalog(cmds, name_pattern, attrs = {})
  return false unless cmds.size == 1 && cmds.first[:name] == "catalog_item"

  payload = cmds.first[:payload]
  return false unless payload[:name] =~ name_pattern

  attrs.all? { |key, value| payload[key] == value }
end

# catalog_item is the only creator; anything else dies as a value downstream
# (ids are grammar-constrained to integers the request cannot know).
def no_creation(cmds)
  cmds.none? { |c| c[:name] == "catalog_item" }
end

def normalized(interpreted)
  Array(interpreted && interpreted[:commands]).filter_map do |raw|
    handler = Registry.command(raw[:name].to_s)
    next if handler.nil? || handler == Capture

    { name: raw[:name].to_s, payload: (raw[:payload] || {}).slice(*handler::PAYLOAD).compact }
  end
end

models = ARGV.presence || [ENV.fetch("INFER_MODEL", "gemma4:e4b")]
capture = Capture.new
schema = CaptureSchema.build

models.each do |model|
  Infer.backend = if model.start_with?("groq:")
    Infer::Groq.new(model: model.delete_prefix("groq:"))
  else
    Infer::Ollama.new(model: model)
  end

  warmup = Benchmark.realtime do
    Infer.structured(schema, prompt: "#{Capture::PROMPT}\n\nRequest: warm up")
  end
  puts format("%s  (load+warmup %.1fs)", model, warmup)

  passed = 0
  latencies = []
  CASES.each do |kase|
    interpreted = nil
    seconds = Benchmark.realtime do
      interpreted = capture.send(:interpret, { utterance: kase[:utterance] })
    end
    latencies << seconds
    cmds = normalized(interpreted)
    ok = kase[:expect].call(cmds)
    passed += 1 if ok
    puts format("  %-28s %s  %5.1fs  %s", kase[:label], ok ? "PASS" : "FAIL", seconds,
                ok ? "" : cmds.inspect[0, 110])
  end

  sorted = latencies.sort
  median = sorted[sorted.size / 2]
  puts format("  => %d/%d passed, median %.1fs, total %.1fs", passed, CASES.size, median, latencies.sum)
  puts
end
