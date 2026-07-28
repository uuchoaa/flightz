class AddParentToCommands < ActiveRecord::Migration[8.1]
  def change
    add_reference :commands, :parent, foreign_key: { to_table: :commands }
  end
end
