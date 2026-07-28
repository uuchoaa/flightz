class AddLevelToCommands < ActiveRecord::Migration[8.1]
  def change
    add_column :commands, :level, :string, null: false, default: "info"
    add_index :commands, :level
  end
end
