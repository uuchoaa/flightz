# The ledger: every write is a row here before it is anything else.
class Command < ApplicationRecord
  enum :status, { pending: "pending", done: "done", failed: "failed" }, default: "pending"

  validates :name, presence: true
end
