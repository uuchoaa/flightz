# The ledger: every write is a row here before it is anything else.
class Command < ApplicationRecord
  belongs_to :parent, class_name: "Command", optional: true
  has_many :children, class_name: "Command", foreign_key: :parent_id, dependent: :destroy
  enum :status, { pending: "pending", done: "done", failed: "failed" }, default: "pending"

  validates :name, presence: true
end
