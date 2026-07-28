class AddParentToCommands < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    add_reference :commands, :parent, foreign_key: { to_table: :commands }
  end
end
