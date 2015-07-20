require 'spec_helper'

describe 'Checkout with Cielo Debt Payment Method', type: :feature do

  include_context 'checkout setup'
  let!(:payment_method) { create(:cielo_debt_payment_method, id: 1) }

  after(:all) do
    Spree::CieloConfig.test_mode = false
    Spree::CieloConfig.afiliation_key = ''
    Spree::CieloConfig.token = ''
    Spree::CieloConfig.debt_cards = []
    Spree::CieloConfig.credit_cards = {}
    Spree::CieloConfig.minimum_value = '5.0'
    Spree::CieloConfig.generate_token = true
  end

  context 'create orders with Cielo Debt' do
    before do
      Spree::CieloConfig.generate_token = false
      Spree::CieloConfig.debt_cards = ['visa']
    end

    it 'should create an valid Cielo Debt payment', js: true do
      # stub the create method
      response = JSON.parse File.read('spec/fixtures/cielo_returns/create_success.json'), symbolize_names: true
      confirm_url = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/cielo_debt/confirm/1/payment_method/1"
      response[:transacao][:'url-autenticacao'] = confirm_url
      allow_any_instance_of(Cielo::Transaction).to receive(:create!).and_return(response)

      # stub the verify method
      verify_response = JSON.parse File.read('spec/fixtures/cielo_returns/purchase_success.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Transaction).to receive(:verify!).and_return(verify_response)

      navigate_to_payment
      fill_debt_card_data

      expect(page).to have_text 'Your order has been processed successfully'
      expect(page).to have_text 'Ending in 1111'

      expect(Spree::Order.complete.count).to eq 1
    end

    it 'should show an error message when the response of Cielo is invalid', js: true do
      stub_cielo_request 'authorize_error'
      navigate_to_payment
      fill_debt_card_data

      expect(page).to have_text 'Cielo: Permission denied'
    end
  end

  context 'coupon code' do
    let!(:promotion) do
      promotion = Spree::Promotion.create(name: '10% off', code: '10off')
      calculator = Spree::Calculator::FlatPercentItemTotal.create(preferred_flat_percent: '10')
      action = Spree::Promotion::Actions::CreateItemAdjustments.create(calculator: calculator)
      promotion.actions << action
      promotion
    end

    it 'should insert coupon code', js: true do
      navigate_to_payment
      fill_in 'Coupon Code', with: '10off'
      click_button 'Authorize'
      expect(page).to have_text 'Coupon code applied successfully.'
    end

    it 'should show an error when the coupon is invalid', js: true do
      navigate_to_payment
      fill_in 'Coupon Code', with: '123'
      click_button 'Authorize'

      expect(page).to have_text "The coupon code you entered doesn't exist. Please try again."
    end
  end
end