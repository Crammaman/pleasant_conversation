class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :question_type, null: false, default: "text"
      t.string :text, null: false
      t.json :config, null: false, default: {}
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
