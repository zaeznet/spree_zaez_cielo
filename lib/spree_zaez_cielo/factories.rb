FactoryGirl.define do
  factory :cielo_credit_payment_method, class: Spree::PaymentMethod::CieloCredit do
    name 'Cielo Credit'
    created_at Date.today
  end

  factory :cielo_debt_payment_method, class: Spree::PaymentMethod::CieloDebt do
    name 'Cielo Debt'
    created_at Date.today
  end

  factory :cielo_credit_payment, class: Spree::Payment do
    amount 15.00
    association(:payment_method, factory: :cielo_credit_payment_method)
    association(:source, factory: :credit_card_cielo)
    order
    state 'checkout'
    portions 2
  end

  factory :cielo_debt_payment, class: Spree::Payment do
    amount 15.00
    association(:payment_method, factory: :cielo_debt_payment_method)
    association(:source, factory: :debt_card_cielo)
    order
    state 'checkout'
    portions 3
  end

  factory :credit_card_cielo, class: Spree::CreditCard do
    verification_value 123
    month 12
    year { 1.year.from_now.year }
    number '4111111111111111'
    name 'Spree Commerce'
    cc_type 'visa'
    association(:payment_method, factory: :cielo_credit_payment_method)
  end

  factory :debt_card_cielo, class: Spree::CreditCard do
    verification_value 123
    month 12
    year { 1.year.from_now.year }
    number '4111111111111111'
    name 'Spree Commerce'
    cc_type 'visa'
    association(:payment_method, factory: :cielo_debt_payment_method)
  end
end
