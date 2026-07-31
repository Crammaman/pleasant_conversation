class CreateProfileQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :queues do |t|
      t.references :profile, null: false, foreign_key: true
      t.date :date
      t.boolean :current, null: false, default: false

      t.timestamps
    end
  end
end
