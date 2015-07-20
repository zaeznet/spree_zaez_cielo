require 'spec_helper'

describe 'Admin Cielo Debt Payment', type: :feature do

  let!(:payment) { create(:cielo_debt_payment) }

  before {  create_admin_and_sign_in }

  context 'executing the actions' do
    it_behaves_like 'admin cielo actions'
  end
end