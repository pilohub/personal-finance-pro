json.extract! expense, :id, :title, :amount, :category, :date, :created_at, :updated_at
json.url expense_url(expense, format: :json)
