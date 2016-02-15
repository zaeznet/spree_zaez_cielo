require 'spec_helper'

describe Spree::PaymentMethod::CieloCredit do

  let(:cielo) { FactoryGirl.build(:cielo_credit_payment_method) }
  let!(:payment) { create(:cielo_credit_payment, source: credit_card) }
  let(:credit_card) { FactoryGirl.build(:credit_card_cielo) }
  let(:gateway_options) { {order_id: "test-#{payment.number}", portions: 2} }

  before do
    payment
    Spree::CieloConfig.generate_token = false
  end

  after(:all) do
    Spree::CieloConfig.generate_token = true
  end

  context 'authorize' do
    it 'should authorize the payment' do
      stub_cielo_request :create!, 'authorize_success'

      response = cielo.authorize(1000, credit_card, gateway_options)
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: transaction authorized successfully'
    end

    context 'using token' do
      it 'should make the request to Cielo using the token' do
        stub_cielo_request :create!, 'authorize_success'
        credit_card.gateway_customer_profile_id = 'test123'

        response = cielo.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: transaction authorized successfully'
      end

      it 'should create the token and save on credit card when the setting is enable' do
        Spree::CieloConfig.generate_token = true
        stub_cielo_request :create!, 'authorize_token_success'

        response = cielo.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: transaction authorized successfully'
        expect(credit_card.gateway_customer_profile_id).to eq '2ta/YqYaeyolf2NHkBWO8grPqZE44j3PvRAQxVQQGgE='
      end

      it 'should not storage the token if the request is unauthorized' do
        Spree::CieloConfig.generate_token = true
        stub_cielo_request :create!, 'authorize_error'

        cielo.authorize(1000, credit_card, gateway_options)
        expect(credit_card.gateway_customer_profile_id).to be_nil
      end
    end

    context 'error' do
      it 'should return an error when the response of Cielo is unauthorized' do
        stub_cielo_request :create!, 'authorize_error'

        response = cielo.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Permission denied'
      end

      it 'should return an error when the request to Cielo is invalid' do
        stub_cielo_request :create!, 'error_001'

        response = cielo.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: The message is invalid. Verify the information and try again.'
      end

      it 'should return an invalid response when occurs an error on authorization' do
        allow_any_instance_of(Cielo::Transaction).to receive(:create!).and_return(nil)

        response = cielo.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try authorize'
      end

      it 'should return an error when any portions is passed' do
        response = cielo.authorize(1000, credit_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: The number of portions is required'
      end
    end
  end

  context 'purchase' do
    it 'should purchase the payment' do
      stub_cielo_request :create!, 'purchase_success'

      response = cielo.purchase(1500, credit_card, gateway_options)
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: transaction purchased successfully'
    end

    context 'using token' do
      it 'should make the request to Cielo using the token' do
        stub_cielo_request :create!, 'purchase_success'
        credit_card.gateway_customer_profile_id = 'test123'

        response = cielo.purchase(1000, credit_card, gateway_options)
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: transaction purchased successfully'
      end

      it 'should create the token and save on credit card when the setting is enable' do
        Spree::CieloConfig.generate_token = true
        stub_cielo_request :create!, 'purchase_token_success'

        response = cielo.purchase(1000, credit_card, gateway_options)
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: transaction purchased successfully'
        expect(credit_card.gateway_customer_profile_id).to eq '2ta/YqYaeyolf2NHkBWO8grPqZE44j3PvRAQxVQQGgE='
      end

      it 'should not storage the token if the request is unauthorized' do
        Spree::CieloConfig.generate_token = true
        stub_cielo_request :create!, 'authorize_error'

        cielo.purchase(1000, credit_card, gateway_options)
        expect(credit_card.gateway_customer_profile_id).to be_nil
      end
    end

    context 'error' do
      it 'should return an error when the response of Cielo is unauthorized' do
        stub_cielo_request :create!, 'authorize_error'

        response = cielo.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Permission denied'
      end

      it 'should return an error when the request to Cielo is invalid' do
        stub_cielo_request :create!, 'error_001'

        response = cielo.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: The message is invalid. Verify the information and try again.'
      end

      it 'should return an invalid response when occurs an error on purchase' do
        allow_any_instance_of(Cielo::Transaction).to receive(:create!).and_return(nil)

        response = cielo.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try purchase'
      end

      it 'should return an error when any portions is passed' do
        response = cielo.purchase(1000, credit_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: The number of portions is required'
      end
    end
  end

  context 'capture' do
    it 'should capture the payment' do
      stub_cielo_request :catch!, 'capture_success'

      response = cielo.capture(1900, '123', {})
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: captured successfully'
    end

    context 'error' do
      it 'should return an invalid response when te request is invalid' do
        stub_cielo_request :catch!, 'capture_error'

        response = cielo.capture(1900, '123', {})
        expect(response.success?).to be false
        expect(response.message).to eq "Cielo: 030 - O status 'Nao autorizada' não permite captura."
      end

      it 'should return an invalid response when occurs an error on capture' do
        allow_any_instance_of(Cielo::Transaction).to receive(:catch!).and_return(nil)

        response = cielo.capture(1900, '123', {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try capture'
      end
    end
  end

  context 'void' do
    it 'should void the payment' do
      stub_cielo_request :cancel!, 'void_success'

      response = cielo.void('123', {})
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: Voided successfully'
    end

    context 'error' do
      it 'should return an invalid response when the request is invalid' do
        stub_cielo_request :cancel!, 'void_error'

        response = cielo.void('123', {})
        expect(response.success?).to be false
        expect(response.message).to eq "Cielo: 041 - O status 'Nao autorizada' não permite cancelamento."
      end

      it 'should return an invalid response when occurs an error on void' do
        allow_any_instance_of(Cielo::Transaction).to receive(:cancel!).and_return(nil)

        response = cielo.void('123', {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try void'
      end
    end
  end

  def stub_cielo_request(method, filename)
    cielo_response = JSON.parse File.read("spec/fixtures/cielo_returns/#{filename}.json"), symbolize_names: true
    allow_any_instance_of(Cielo::Transaction).to receive(method).and_return(cielo_response)
  end
end