class AddNecessityToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :necessity, :integer
  end
end
