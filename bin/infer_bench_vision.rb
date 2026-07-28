# Vision interpreter benchmark: photo -> proposals, same prompt and grammar
# as the capture photo path. Scores at interpretation altitude.
#
#   bin/rails runner bin/infer_bench_vision.rb gemma3:4b groq:qwen/qwen3.6-27b
#
# Fixtures in test/fixtures/files/vision (Wikimedia Commons).

require "benchmark"
require "base64"

FIXTURES = Rails.root.join("test/fixtures/files/vision")

CASES = [
  {
    label: "blender on the counter",
    file: "blender.jpg",
    expect: ->(cmds) { catalogs(cmds).any? { |c| c[:payload][:name] =~ /blender|nutribullet/i } },
  },
  {
    label: "acoustic guitar",
    file: "guitar.jpg",
    expect: ->(cmds) { catalogs(cmds).any? { |c| c[:payload][:name] =~ /guitar|violao|resonator/i } },
  },
  {
    label: "no-op: mountain landscape",
    file: "landscape.jpg",
    expect: ->(cmds) { catalogs(cmds).empty? },
  },
].freeze

def catalogs(cmds)
  cmds.select { |c| c[:name] == "catalog_item" }
end

def normalized(interpreted)
  Array(interpreted && interpreted[:commands]).filter_map do |raw|
    handler = Registry.command(raw[:name].to_s)
    next if handler.nil? || handler == Capture

    { name: raw[:name].to_s, payload: (raw[:payload] || {}).slice(*handler::PAYLOAD).compact }
  end
end

capture = Capture.new
schema = CaptureSchema.build
prompt = capture.send(:prompt_for, { image: "present" })

models = ARGV.presence || ["gemma3:4b"]
models.each do |model|
  Infer.backend = if model.start_with?("groq:")
    Infer::Groq.new(model: model.delete_prefix("groq:"))
  else
    Infer::Ollama.new(model: model, vision_model: model)
  end

  passed = 0
  latencies = []
  CASES.each do |kase|
    image = Base64.strict_encode64(File.binread(FIXTURES.join(kase[:file])))
    interpreted = nil
    seconds = Benchmark.realtime do
      interpreted = Infer.structured(schema, prompt: prompt, images: [image])
    end
    latencies << seconds
    cmds = normalized(interpreted)
    ok = kase[:expect].call(cmds)
    passed += 1 if ok
    puts format("  %-28s %s  %5.1fs  %s", kase[:label], ok ? "PASS" : "FAIL", seconds,
                ok ? "" : cmds.inspect[0, 110])
  end
  puts format("%s => %d/%d passed, total %.1fs", model, passed, CASES.size, latencies.sum)
  puts
end
