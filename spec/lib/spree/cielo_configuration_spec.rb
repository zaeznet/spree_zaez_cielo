require 'spec_helper'

describe Spree::CieloConfiguration do

  let(:config) { subject.class.new }

  [:afiliation_key, :token, :test_mode, :minimum_value, :debt_cards, :credit_cards,
   :tax_value, :portion_without_tax, :product_value, :generate_token].each do |preference|
    it "should has the #{preference} preference" do
      expect(config.has_preference?(preference)).to be true
    end
  end

  after(:all) do
    Spree::CieloConfig.credit_cards = {}
    Spree::CieloConfig.tax_value = '0.00'
    Spree::CieloConfig.minimum_value = '5.00'
    Spree::CieloConfig.portion_without_tax = 1
  end

  context 'calculate a single portion' do
    it 'should calculate without tax' do
      config.portion_without_tax = 10
      portion_value = config.calculate_portion_value 100.0, 4
      expect(portion_value).to eq 25.0
    end

    it 'should calculate with tax' do
      config.portion_without_tax = 1
      config.tax_value = '5.00'
      portion_value = config.calculate_portion_value 100.0, 4
      expect(portion_value).to eq 30.387656250000006
    end
  end

  context 'calculating some portions' do
    it 'should calculate portions without tax' do
      config.portion_without_tax = 10
      config.credit_cards = {'visa' => 5}
      portions = config.calculate_portions 100.0, 'visa'

      expect(portions[0]).to eq({portion: 1, value: 100.0, total: 100.0, tax_message: :cielo_without_tax})
      expect(portions[1]).to eq({portion: 2, value: 50.0, total: 100.0, tax_message: :cielo_without_tax})
      expect(portions[2]).to eq({portion: 3, value: 33.333333333333336, total: 100.0, tax_message: :cielo_without_tax})
      expect(portions[3]).to eq({portion: 4, value: 25.0, total: 100.0, tax_message: :cielo_without_tax})
      expect(portions[4]).to eq({portion: 5, value: 20.0, total: 100.0, tax_message: :cielo_without_tax})
    end

    it 'should return the number of portions respecting the minimum value' do
      config.credit_cards = {'master' => 10}
      config.minimum_value = 20
      config.portion_without_tax = 12
      portions = config.calculate_portions 50.0, 'master'

      expect(portions.size).to eq 2
    end

    it 'should calculate portions with tax' do
      config.credit_cards = {'master' => 6}
      config.minimum_value = 10
      config.portion_without_tax = 1
      config.tax_value = '1'
      portions = config.calculate_portions 100.0, 'master'

      expect(portions[0]).to eq({portion: 1, value: 100.0, total: 100.0, tax_message: :cielo_without_tax})
      expect(portions[1]).to eq({portion: 2, value: 51.005, total: 102.01, tax_message: :cielo_with_tax})
      expect(portions[2]).to eq({portion: 3, value: 34.343366666666675, total: 103.03010000000003, tax_message: :cielo_with_tax})
      expect(portions[3]).to eq({portion: 4, value: 26.01510025, total: 104.060401, tax_message: :cielo_with_tax})
      expect(portions[4]).to eq({portion: 5, value: 21.020201002, total: 105.10100501, tax_message: :cielo_with_tax})
      expect(portions[5]).to eq({portion: 6, value: 17.692002510016668, total: 106.15201506010001, tax_message: :cielo_with_tax})
    end
  end
end