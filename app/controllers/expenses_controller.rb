class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ] 

  def index
    # 1. Phelathi badha expenses lo
    @expenses = Expense.all.order(date: :desc)
    
    # --- PHASE 2: FILTER LOGIC ---
    # Jo user e Category select kari hoy
    if params[:category].present?
      @expenses = @expenses.where(category: params[:category])
    end

    # Jo user e Mahino (Month) select karyo hoy
    if params[:month].present?
      start_date = Date.parse("#{params[:month]}-01")
      end_date = start_date.end_of_month
      @expenses = @expenses.where(date: start_date..end_date)
    end
    # -----------------------------

    @total_expense = @expenses.sum(:amount)
    
    # Budget ane Balance
    @monthly_budget = session[:budget] ? session[:budget].to_f : 50000.0
    @balance = @monthly_budget - @total_expense
    
    # Category Graph mate data
    @category_data = @expenses.group(:category).sum(:amount)

    # --- NO-SPEND STREAK LOGIC ---
    last_expense_date = Expense.maximum(:date)
    
    if last_expense_date
      # Calculate difference in days between today and the last expense
      @streak = (Date.today - last_expense_date.to_date).to_i
      @streak = 0 if @streak < 0 # Prevents negative streaks if future dates are entered
    else
      @streak = 0
    end
    # -----------------------------
    
    # --- SUBSCRIPTION TRACKER LOGIC ---
    @subscriptions = Subscription.all.order(due_day: :asc)
    @total_subscription_amount = @subscriptions.sum(:amount)
# CA-Ready Ultimate Professional CSV Export Logic
    respond_to do |format|
      format.html
      format.csv do
        require 'csv'
        csv_data = CSV.generate(headers: true) do |csv|
          # 1. Company / Project Header
          csv << ["Personal Finance Pro - Ultimate Financial Report"]
          csv << ["Generated On:", Date.today.strftime("%d-%m-%Y")]
          csv << []
          
          # 2. Executive Summary (Budget, Expenses, Balance)
          csv << ["--- FINANCIAL SUMMARY ---"]
          csv << ["Monthly Budget", "Total Expenses", "Available Balance", "Budget Utilization %"]
          util_pct = @monthly_budget > 0 ? ((@total_expense / @monthly_budget) * 100).round(1) : 0
          csv << [@monthly_budget, @total_expense, @balance, "#{util_pct}%"]
          csv << []

          # 3. Dream Savings Goal Section
          csv << ["--- DREAM SAVINGS GOAL ---"]
          csv << ["Goal Title", "Target Amount (INR)", "Current Saved (INR)", "Progress %"]
          if @goal
            goal_pct = @goal.target_amount > 0 ? ((@goal.current_amount / @goal.target_amount) * 100).round(1) : 0
            csv << [@goal.title, @goal.target_amount, @goal.current_amount, "#{goal_pct}%"]
          end
          csv << []

          # 4. Active Subscriptions & EMIs Section
          csv << ["--- ACTIVE SUBSCRIPTIONS & EMIs ---"]
          csv << ["Service Name", "Due Day", "Monthly Amount (INR)"]
          if @subscriptions && @subscriptions.any?
            @subscriptions.each do |sub|
              csv << [sub.name, "Every #{sub.due_day}th", sub.amount]
            end
            csv << ["Total Fixed Commitments:", "", @total_subscription_amount]
          else
            csv << ["No active subscriptions found"]
          end
          csv << []

          # 5. Detailed Transaction History
          csv << ["--- DETAILED TRANSACTION HISTORY ---"]
          csv << ["Transaction Title", "Category", "Date", "Necessity Level (1-5)", "Amount (INR)"]
          
          @expenses.each do |expense|
            csv << [
              expense.title, 
              expense.category, 
              expense.date.strftime("%d/%m/%Y"), 
              expense.necessity || 1, 
              expense.amount
            ]
          end
          
          csv << []
          csv << ["", "", "", "Grand Total Expenses:", @expenses.sum(:amount)]
        end
        
        # Excel માટે UTF-8 BOM ફરજિયાત
        send_data "\xEF\xBB\xBF" + csv_data, filename: "Ultimate_Finance_Report_#{Date.today}.csv", type: 'text/csv; charset=utf-8'
      end
    end

    # --- GOAL TRACKER LOGIC ---
    # Database mathi phelu goal lavo, jo na hoy to ek default dummy goal batave
    @goal = Goal.first || Goal.new(title: 'My Dream Goal', target_amount: 100000, current_amount: 0)
  end

  def set_budget
    session[:budget] = params[:budget]
    redirect_to root_path, notice: "Monthly budget updated successfully!"
  end

  # --- GOAL UPDATE LOGIC ---
  def update_goal
    @goal = Goal.first || Goal.new
    @goal.update(
      title: params[:title],
      target_amount: params[:target_amount],
      current_amount: params[:current_amount]
    )
    redirect_to expenses_path, notice: "Goal updated successfully!"
  end

  # --- ADD SUBSCRIPTION LOGIC ---
  def add_subscription
    Subscription.create(
      name: params[:name],
      amount: params[:amount],
      due_day: params[:due_day]
    )
    redirect_to expenses_path, notice: "Subscription added successfully!"
  end

  # GET /expenses/1 or /expenses/1.json
  def show
  end

  # GET /expenses/new
  def new
    @expense = Expense.new
  end

  # GET /expenses/1/edit
  def edit
  end

  # POST /expenses or /expenses.json
  def create
    @expense = Expense.new(expense_params)

    respond_to do |format|
      if @expense.save
        format.html { redirect_to @expense, notice: "Expense was successfully created." }
        format.json { render :show, status: :created, location: @expense }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @expense.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /expenses/1 or /expenses/1.json
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html { redirect_to @expense, notice: "Expense was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @expense.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /expenses/1 or /expenses/1.json
  def destroy
    @expense.destroy!

    respond_to do |format|
      format.html { redirect_to expenses_path, notice: "Expense was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_expense
      @expense = Expense.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def expense_params
      params.expect(expense: [ :title, :amount, :category, :date, :necessity ])
    end
end