require 'csv'

class Expense < ApplicationRecord
  # Save thava pela automatic guilt score calculate thase
  before_save :auto_calculate_guilt

  def self.to_csv
    attributes = %w{title amount category date}
    CSV.generate(headers: true) do |csv|
      csv << attributes.map(&:capitalize)
      all.each do |expense|
        csv << attributes.map{ |attr| expense.send(attr) }
      end
    end
  end

  private

  # AUTOMATIC ANALYSIS LOGIC
  def auto_calculate_guilt
    # Title ane Category ne ek sathe milaavi ne lowercase ma convert karyu
    full_text = "#{title} #{category}".downcase

    # 1. Total Waste / Pure Luxury (Score: 5)
    if full_text.match?(/zomato|swiggy|party|pub|club|starbucks|movie|gaming|iphone|luxury|cafe/)
      self.necessity = 5

    # 2. Moderate / Non-Essential Shopping (Score: 3 ke 4)
    elsif full_text.match?(/shopping|clothes|restaurant|snack|recharge|amazon|flipkart/)
      self.necessity = 3

    # 3. Absolute Need / Essential Expenses (Score: 1 ke 2)
    elsif full_text.match?(/rent|bill|fee|electricity|hospital|medicine|grocery|petrol|fuel|milk|tax/)
      self.necessity = 1

    # 4. Default / Neutral (Jo koi match na thay to Score: 2)
    else
      self.necessity = 2
    end
  end
end