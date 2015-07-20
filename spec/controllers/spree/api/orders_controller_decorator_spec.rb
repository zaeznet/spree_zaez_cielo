require 'spec_helper'

describe Spree::Api::OrdersController, type: :controller do
  render_views

  context 'portions' do
    after(:all) do
      # set default
      Spree::CieloConfig.credit_cards = {}
      Spree::CieloConfig.minimum_value = '0.0'
      Spree::CieloConfig.portion_without_tax = 1
      Spree::CieloConfig.tax_value = '0.0'
    end

    let(:order) { create(:order, total: '200') }

    it 'should return an error message when the credit card type is not available' do
      Spree::CieloConfig.credit_cards = {'visa' => 10}
      api_get :portions, id: order.to_param, cc_type: 'master'

      expect(response.status).to eq 500
      ret = JSON.parse response.body
      expect(ret).to eq({'error' => 'The credit card is not supported.'})
    end

    it 'should calculate the portions according to Cielo settings' do
      # definido cartao mastercard com ate 10 parcelas
      # com o minimo de cada parcela sendo 20.00
      # e com ate 12 parcelas sem juros
      #
      # o retorno deve ser de 10 parcelas, todas sem juros
      Spree::CieloConfig.credit_cards = {'master' => 10}
      Spree::CieloConfig.minimum_value = 20
      Spree::CieloConfig.portion_without_tax = 12

      api_get :portions, id: order.to_param, cc_type: 'master'

      ret = JSON.parse response.body
      expect(ret.size).to eq 10

      ret.each_with_index do |item, i|
        number = i + 1
        tot = sprintf('%.02f', 200.0 / number)
        item_expected = {'portion' => number, 'value' => "$#{tot}", 'tax_message' => 'cielo_without_tax', 'total' => '$200.00'}
        expect(item).to eq item_expected
      end
    end

    it 'should calculate the portions respecting the minimum value' do
      # definido cartao mastercard com ate 10 parcelas
      # com o minimo de cada parcela sendo 20.00
      # e com ate 12 parcelas sem juros
      #
      # o retorno deve ser de 2 parcelas
      Spree::CieloConfig.credit_cards = {'master' => 10}
      Spree::CieloConfig.minimum_value = 100
      Spree::CieloConfig.portion_without_tax = 12

      api_get :portions, id: order.to_param, cc_type: 'master'

      ret = JSON.parse response.body
      expect(ret.size).to eq 2
    end

    it 'should calculate the tax of the portions' do
      # definido cartao mastercard com ate 6 parcelas
      # com o minimo de cada parcela sendo 10.00
      # e com 1 parcela sem juros
      #
      # o retorno deve ser de 6 parcelas (a 1a sem juros e as outras com)
      Spree::CieloConfig.credit_cards = {'master' => 6}
      Spree::CieloConfig.minimum_value = 10
      Spree::CieloConfig.portion_without_tax = 1
      Spree::CieloConfig.tax_value = '1'

      api_get :portions, id: order.to_param, cc_type: 'master'

      ret = JSON.parse response.body
      expect(ret.size).to eq 6

      expect(ret[0]).to eq({'portion' => 1, 'value' => '$200.00', 'tax_message' => 'cielo_without_tax', 'total' => '$200.00'})
      expect(ret[1]).to eq({'portion' => 2, 'value' => '$102.01', 'tax_message' => 'cielo_with_tax', 'total' => '$204.02'})
      expect(ret[2]).to eq({'portion' => 3, 'value' => '$68.69',  'tax_message' => 'cielo_with_tax', 'total' => '$206.06'})
      expect(ret[3]).to eq({'portion' => 4, 'value' => '$52.03',  'tax_message' => 'cielo_with_tax', 'total' => '$208.12'})
      expect(ret[4]).to eq({'portion' => 5, 'value' => '$42.04',  'tax_message' => 'cielo_with_tax', 'total' => '$210.20'})
      expect(ret[5]).to eq({'portion' => 6, 'value' => '$35.38',  'tax_message' => 'cielo_with_tax', 'total' => '$212.30'})
    end
  end
end