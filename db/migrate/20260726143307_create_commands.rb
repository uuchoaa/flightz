class CreateCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :commands do |t|
      t.string :name, null: false
      t.json :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.json :result
      t.timestamps
    end
    add_index :commands, :status
  end
end
