# Key-value store for app configuration; values are JSON scalars. Defaults
# live with the use cases (Settings::DEFAULTS) — this ring only persists.
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.put(key, value)
    find_or_initialize_by(key: key.to_s).update!(value: value)
  end

  def self.all_values
    pluck(:key, :value).to_h
  end
end
