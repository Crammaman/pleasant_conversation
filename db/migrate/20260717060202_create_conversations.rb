class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :queue, null: false, foreign_key: true
      t.string :state, null: false, default: "pending"
      t.string :name, null: false

      t.timestamps
    end
  end
end
