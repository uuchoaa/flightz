require "test_helper"
require "tmpdir"

class GoogleFlights::TokensTest < ActiveSupport::TestCase
  FRESH = {
    "X-Goog-BatchExecute-Bgr" => "bgr", "X-Goog-Ext-259736195-Jspb" => "jspb",
    "X-Browser-Validation" => "val", "f.sid" => "sid", "bl" => "bl-tag"
  }.freeze

  FakeExtractor = Struct.new(:tokens, :calls) do
    def extract(log: nil)
      self.calls = (calls || 0) + 1
      tokens
    end
  end

  setup do
    @cache = File.join(Dir.mktmpdir, "tokens.json")
  end

  test "extracts lazily and caches in memory and on disk" do
    extractor = FakeExtractor.new(FRESH.dup)
    tokens = GoogleFlights::Tokens.new(extractor:, cache_path: @cache)

    assert_equal "bgr", tokens.fetch["X-Goog-BatchExecute-Bgr"]
    tokens.fetch
    assert_equal 1, extractor.calls
    assert JSON.parse(File.read(@cache))["tokens"].key?("f.sid")
  end

  test "reuses a fresh disk cache without extracting" do
    GoogleFlights::Tokens.new(extractor: FakeExtractor.new(FRESH.dup), cache_path: @cache).fetch
    extractor = FakeExtractor.new(FRESH.merge("bl" => "second"))

    assert_equal "bl-tag", GoogleFlights::Tokens.new(extractor:, cache_path: @cache).fetch["bl"]
    assert_nil extractor.calls
  end

  test "re-extracts once the ttl passes" do
    clock = Struct.new(:now).new(Time.now)
    extractor = FakeExtractor.new(FRESH.dup)
    tokens = GoogleFlights::Tokens.new(extractor:, cache_path: @cache, ttl: 60, clock:)

    tokens.fetch
    clock.now += 120
    extractor.tokens = FRESH.merge("bl" => "refreshed")
    assert_equal "refreshed", tokens.fetch["bl"]
    assert_equal 2, extractor.calls
  end

  test "falls back to stale tokens when extraction dies" do
    clock = Struct.new(:now).new(Time.now)
    extractor = FakeExtractor.new(FRESH.dup)
    tokens = GoogleFlights::Tokens.new(extractor:, cache_path: @cache, ttl: 60, clock:)

    tokens.fetch
    clock.now += 120
    extractor.tokens = nil
    assert_equal "bl-tag", tokens.fetch["bl"]
  end

  test "falls back to the HAR seed when there is nothing at all" do
    tokens = GoogleFlights::Tokens.new(extractor: FakeExtractor.new(nil), cache_path: @cache)
    assert_equal GoogleFlights::Tokens::SEED["bl"], tokens.fetch["bl"]
  end
end
