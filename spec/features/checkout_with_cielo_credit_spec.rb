require 'spec_helper'

describe 'Checkout with Cielo Credit Payment Method', type: :feature do

  include_context 'checkout setup'
  let!(:payment_method) { create(:cielo_credit_payment_method, id: 1) }

  after(:all) do
    Spree::CieloConfig.test_mode = false
    Spree::CieloConfig.afiliation_key = ''
    Spree::CieloConfig.token = ''
    Spree::CieloConfig.credit_cards = {}
    Spree::CieloConfig.minimum_value = '5.0'
    Spree::CieloConfig.generate_token = true
  end

  context 'create order without token' do
    before { Spree::CieloConfig.generate_token = false }

    it 'should create an valid Cielo Credit payment', js: true do
      stub_cielo_request
      navigate_to_payment
      fill_credit_card_data

      expect(page).to have_text 'Your order has been processed successfully'
      expect(page).to have_text 'Ending in 1111'

      expect(Spree::Order.complete.count).to eq 1
    end

    it 'should show an error message when the response of Cielo is invalid', js: true do
      stub_cielo_request 'authorize_error'
      navigate_to_payment
      fill_credit_card_data

      expect(page).to have_text 'Cielo: Permission denied'
      expect(Spree::Order.first.payments.last.state).to eq 'failed'
    end
  end

  context 'creating a token and using' do
    it 'should create a token and use in next transactions', js: true do
      Spree::CieloConfig.generate_token = true

      response = JSON.parse File.read('spec/fixtures/cielo_returns/token_success.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Token).to receive(:create!).and_return(response)
      stub_cielo_request

      navigate_to_payment
      fill_credit_card_data
      expect(page).to have_text 'Your order has been processed successfully'
      expect(page).to have_text 'Ending in 1111'
      expect(Spree::Order.complete.count).to eq 1
      expect(Spree::Order.last.credit_cards.with_payment_profile.count).to eq 1

      navigate_to_payment true
      choose 'Use an existing card on file'
      choose '2x of $5.00 without tax'
      # confirm payment method
      click_button 'Save and Continue'

      expect(page).to have_text 'Your order has been processed successfully'
      expect(page).to have_text 'Ending in 1111'
      expect(page).to have_text 'Quantity of portions: 2x'
      expect(Spree::Order.complete.count).to eq 2
    end
  end
end