# Errors as values: every use case returns a Result. No exception crosses a
# layer boundary to signal a domain outcome; raising is reserved for bugs.
class Result
  attr_reader :value, :code, :details, :notice

  def self.ok(value = nil, notice: nil)
    new(true, value:, notice:)
  end

  def self.err(code, details = nil)
    new(false, code:, details:)
  end

  def initialize(ok, value: nil, code: nil, details: nil, notice: nil)
    @ok = ok
    @value = value
    @code = code
    @details = details
    @notice = notice
  end

  def ok? = @ok
  def err? = !@ok

  def deconstruct_keys(_keys)
    ok? ? { ok: value } : { err: { code:, details: } }
  end

  def as_json(*)
    if ok?
      { "ok" => value.as_json }
    else
      { "err" => { "code" => code.to_s, "details" => details.as_json }.compact }
    end
  end
end
