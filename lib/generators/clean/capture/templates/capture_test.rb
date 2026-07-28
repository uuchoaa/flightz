require "test_helper"

# Domain-blind capture behavior; domain round-trips live in the app's own
# integration tests.
class CaptureTest < ActiveSupport::TestCase
  teardown { Infer.backend = Infer::Static.new }

  test "interpreter down degrades to a value" do
    Infer.backend = Infer::Static.new
    result = Capture.new.call({ utterance: "anything" })
    assert result.err?
    assert_equal :interpreter_down, result.code
  end

  test "unknown commands are filtered out, never dispatched" do
    Infer.backend = Infer::Static.new(structured: [{ commands: [{ name: "bogus", payload: {} }] }])
    result = Capture.new.call({ utterance: "anything" })
    assert result.err?
    assert_equal :nothing_understood, result.code
  end

  test "capture never dispatches itself" do
    Infer.backend = Infer::Static.new(structured: [{ commands: [{ name: "capture", payload: {} }] }])
    result = Capture.new.call({ utterance: "anything" })
    assert_equal :nothing_understood, result.code
  end
end
