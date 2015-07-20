require 'spec_helper'

describe Spree::Payment::GatewayOptions do

  let(:options) { Spree::Payment::GatewayOptions.new(payment) }

  let(:payment) do
    double(
        Spree::Payment,
        portions: 3,
        order: order,
        number: 'P123',
        currency: 'USD'
    )
  end

  let(:order) do
    double(
        Spree::Order,
        email: 'test@email.com',
        user_id: 144,
        last_ip_address: '0.0.0.0',
        number: 'R1444',
        ship_total: 12.3,
        additional_tax_total: 13.21,
        item_total: 12.3,
        promo_total: 2.5,
        bill_address: bill_address,
        ship_address: ship_address
    )
  end

  let(:bill_address) do
    double Spree::Address, active_merchant_hash: { bill: :address }
  end
  let(:ship_address) do
    double Spree::Address, active_merchant_hash: { ship: :address }
  end

  context 'add portions to gateway options' do
    it { expect(options.portions).to eq 3 }

    it 'should has the portions symbol on collection' do
      expect(options.hash_methods).to include(:portions)
    end

    it 'should return the number of portions' do
      expect(options.to_hash[:portions]).to eq 3
    end
  end
end