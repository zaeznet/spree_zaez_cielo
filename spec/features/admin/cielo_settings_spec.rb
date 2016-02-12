require 'spec_helper'

describe 'Cielo Settings', type: :feature do
  before { create_admin_and_sign_in }

  context 'visit Cielo cielo_settings' do
    it 'should be a link to Cielo cielo_settings' do
      within('.sidebar') { page.find_link('Cielo Settings')['/admin/cielo_settings/edit'] }
    end
  end

  context 'show Cielo cielo_settings' do
    it 'should be the fields of Cielo cielo_settings', js: true do
      visit spree.edit_admin_cielo_settings_path

      expect(page).to have_selector '#afiliation_key'
      expect(page).to have_selector '#token'
      expect(page).to have_selector '#test_mode'
      expect(page).to have_selector '#minimum_value'
      expect(page).to have_selector '#portion_without_tax'
      expect(page).to have_selector '#tax_value'
      expect(page).to have_selector '#cielo_cards'
      expect(page).to have_selector '[name=product_value]'
      expect(page).to have_selector '#soft_descriptor'
    end
  end

  context 'edit Cielo cielo_settings' do
    before { visit spree.edit_admin_cielo_settings_path }

    it 'can edit test mode', js: true do
      find(:css, '#test_mode').set true
      click_button 'Update'

      expect(Spree::CieloConfig.test_mode).to be true
      expect(find_field('test_mode')).to be_checked

      # set default
      Spree::CieloConfig.test_mode = false
    end

    it 'can edit generate token', js: true do
      find(:css, '#generate_token_false').set true
      click_button 'Update'

      expect(Spree::CieloConfig.generate_token).to be false
      expect(find_field('generate_token_false')).to be_checked

      # set default
      Spree::CieloConfig.generate_token = true
    end

    it 'can edit product value', js: true do
      find(:css, '#product_value_3').set true
      click_button 'Update'

      expect(Spree::CieloConfig.product_value).to eq '3'
      expect(find_field('product_value_3')).to be_checked

      # set default
      Spree::CieloConfig.product_value = '2'
    end

    {afiliation_key: '123',
     token: 'abc1234',
     minimum_value: '1',
     portion_without_tax: 1,
     tax_value: '10',
     soft_descriptor: 'soft desc.'}.each do |key, value|

      it "can edit #{key.to_s.humanize}", js: true do
        fill_in key.to_s, with: value
        click_button 'Update'

        expect(Spree::CieloConfig[key]).to eq value
        expect(find_field(key).value).to eq value.to_s

        # set default
        Spree::CieloConfig[key] = ''
      end
    end

    [:visa, :master, :diners, :elo, :discover, :amex, :jcb, :aura].each do |card|
      it "can edit #{card} credit card", js: true do
        find(:css, "#credit_#{card}_state").set true
        fill_in "#{card}_portion", with: 12
        click_button 'Update'

        expect(Spree::CieloConfig.credit_cards[card.to_s]).to eq 12
        expect(find(:css, "#credit_#{card}_state").value).to eq 'true'
        expect(find(:css, "##{card}_portion").value).to eq '12'

        # set default
        Spree::CieloConfig.credit_cards = {}
      end
    end

    [:visa, :master].each do |card|
      it "can enable/disable the #{card} debt card", js: true do
        find(:css, "#debt_#{card}_state").set true
        click_button 'Update'

        expect(Spree::CieloConfig.debt_cards).to include(card.to_s)
        expect(find(:css, "#debt_#{card}_state").value).to eq card.to_s

        # set default
        Spree::CieloConfig.debt_cards = {}
      end
    end
  end
end