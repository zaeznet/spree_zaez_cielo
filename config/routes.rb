Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :cielo_settings, only: [:show, :edit, :update]
  end

  namespace :api do
    get 'orders/:id/portions', to: 'orders#portions', as: :order_portions
  end

  post 'cielo_debt/create', to: 'cielo_debt#create', as: :cielo_debt_create
  get  'cielo_debt/confirm/:credit_card_id/payment_method/:payment_method_id', to: 'cielo_debt#confirm', as: :cielo_debt_confirm
  post 'cielo_debt/confirm/:credit_card_id/payment_method/:payment_method_id', to: 'cielo_debt#confirm'
end
