shared_context 'checkout setup' do
  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, name: 'RoR Mug', price: 10.0) }
  let!(:zone) { create(:zone) }
  let!(:store) { create(:store) }
end
