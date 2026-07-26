class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.string :title
      t.decimal :target_amount
      t.decimal :current_amount

      t.timestamps
    end
  end
end
