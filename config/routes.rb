Rails.application.routes.draw do
  devise_for :users, controllers: { passwords: 'users/passwords' }
  resources :expenses do
    collection do
      post :set_budget
      post :update_goal
      post :add_subscription
    end
  end
  root "expenses#index"
end