class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :conversation, null: false, foreign_key: true
      # Nullable: answers outlive deleted questions, keeping question_text as the snapshot.
      t.references :question, null: true, foreign_key: true
      t.text :value
      t.string :question_text

      t.timestamps
    end
  end
end
