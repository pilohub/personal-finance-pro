class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.decimal :amount
      t.integer :due_day

      t.timestamps
    end
  end
end
