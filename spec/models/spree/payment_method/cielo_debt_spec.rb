require 'spec_helper'

describe Spree::PaymentMethod::CieloDebt do

  let(:cielo) { create(:cielo_debt_payment_method) }
  let(:debt_card) { create(:debt_card_cielo) }

  context 'create' do
    before do
      test_store = Spree::Store.new(url: 'http://localhost:3000', name: 'teste', code: '123', mail_from_address: 'teste@spree.com')
      allow(Spree::Store).to receive(:current).and_return(test_store)
    end

    it 'should create the transaction' do
      stub_cielo_request :create!, 'create_success'

      response = cielo.create(10000, debt_card)
      expect(response[:url_auth]).to eq 'https://qasecommerce.cielo.com.br/web/index.cbmp?id=79b4e5c277cab56d7f34b01feca4ab6e'
      expect(response[:tid]).to eq '100699306931F0A2A001'
    end

    context 'error' do
      it 'should return an error when the request to Cielo is invalid' do
        stub_cielo_request :create!, 'error_001'

        response = cielo.create(10000, debt_card)
        expect(response[:error]).to eq 'Cielo: The message is invalid. Verify the information and try again.'
      end

      it 'should return an error when the response of Cielo is an error' do
        stub_cielo_request :create!, 'create_error'

        response = cielo.create(10000, debt_card)
        expect(response[:error]).to eq 'Cielo: 086 - Obrigatório o envio dos campos CAVV e XID'
      end

      it 'should return an invalid response when occurs an error on purchase' do
        allow_any_instance_of(Cielo::Transaction).to receive(:create!).and_return(nil)

        response = cielo.create(10000, debt_card)
        expect(response[:error]).to eq 'Cielo: Error when try create the transaction'
      end
    end
  end

  context 'purchase' do
    it 'should purchase the payment' do
      # for purchase method, it is just verify the status of transaction,
      # because the transaction was created on create method
      stub_cielo_request :verify!, 'purchase_success'

      response = cielo.purchase(19500, debt_card, {})
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: transaction purchased successfully'
    end

    context 'error' do
      it 'should return an invalid response when te request is invalid' do
        stub_cielo_request :verify!, 'authorize_error'

        response = cielo.purchase(1900, debt_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Permission denied'
      end

      it 'should return an invalid response when occurs an error on purchase' do
        allow_any_instance_of(Cielo::Transaction).to receive(:verify!).and_return(nil)

        response = cielo.purchase(19500, debt_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try purchase'
      end
    end
  end

  context 'authorize' do
    it 'should capture the payment' do
      # for capture method, it is just verify the status of transaction,
      # because the transaction was created on create method
      stub_cielo_request :verify!, 'authorize_success'

      response = cielo.authorize(1500, debt_card, {})
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: transaction authorized successfully'
    end

    context 'error' do
      it 'should return an invalid response when te request is invalid' do
        stub_cielo_request :verify!, 'authorize_error'

        response = cielo.authorize(1500, debt_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Permission denied'
      end

      it 'should return an invalid response when occurs an error on authorization' do
        allow_any_instance_of(Cielo::Transaction).to receive(:verify!).and_return(nil)

        response = cielo.authorize(1500, debt_card, {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try authorize'
      end
    end
  end

  context 'capture' do
    it 'should capture the payment' do
      stub_cielo_request :catch!, 'capture_success'

      response = cielo.capture(1500, '123', {})
      expect(response.success?).to be true
      expect(response.message).to eq 'Cielo: captured successfully'
    end

    context 'error' do
      it 'should return an invalid response when te request is invalid' do
        stub_cielo_request :catch!, 'capture_error'

        response = cielo.capture(1500, '123', {})
        expect(response.success?).to be false
        expect(response.message).to eq "Cielo: 030 - O status 'Nao autorizada' não permite captura."
      end

      it 'should return an invalid response when occurs an error on capture' do
        allow_any_instance_of(Cielo::Transaction).to receive(:catch!).and_return(nil)

        response = cielo.capture(1500, '123', {})
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try capture'
      end
    end
  end

  context 'void' do
    it 'should void the transaction' do
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

  context 'cancel' do

    context 'successfull canceled' do

      it 'when transaction is authorized or captured' do
        stub_cielo_request :verify!, 'authorize_success'
        stub_cielo_request :cancel!, 'void_success'

        response = cielo.cancel('123')
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: Canceled successfully'
      end

      it 'when transaction is created' do
        stub_cielo_request :verify!, 'create_success'
        stub_cielo_request :cancel!, 'void_success'

        response = cielo.cancel('123')
        expect(response.success?).to be true
        expect(response.message).to eq 'Cielo: Canceled successfully'
      end

    end

    context 'error' do

      it 'should return an invalid response when the request is invalid' do
        stub_cielo_request :verify!, 'authorize_success'
        stub_cielo_request :cancel!, 'void_error'

        response = cielo.cancel('123')
        expect(response.success?).to be false
        expect(response.message).to eq "Cielo: 041 - O status 'Nao autorizada' não permite cancelamento."
      end

      it 'should return an invalid response when occurs an error on void' do
        stub_cielo_request :verify!, 'authorize_success'
        allow_any_instance_of(Cielo::Transaction).to receive(:cancel!).and_return(nil)

        response = cielo.cancel('123')
        expect(response.success?).to be false
        expect(response.message).to eq 'Cielo: Error when try cancel'
      end
    end
  end

  def stub_cielo_request(method, filename)
    cielo_response = JSON.parse File.read("spec/fixtures/cielo_returns/#{filename}.json"), symbolize_names: true
    allow_any_instance_of(Cielo::Transaction).to receive(method).and_return(cielo_response)
  end
end