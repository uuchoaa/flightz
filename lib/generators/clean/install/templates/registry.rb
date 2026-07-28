# The domain publishes its input boundaries here; controllers know no
# use-case class names. Entries are maintained by the clean: generators
# (behind the sentinels) and completeness is enforced by the architecture
# test. Dispatch is an explicit allowlist — never const_get on user input.
module Registry
  COMMANDS = {
    # clean:commands
  }.freeze

  QUERIES = {
    # clean:queries
  }.freeze

  def self.command(name) = COMMANDS[name.to_s]
  def self.query(name) = QUERIES[name.to_s]
end
