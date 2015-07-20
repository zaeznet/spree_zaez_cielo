# Navigate to payment state
# putting a product on the cart,
# filling in the email,
# setting the address and selecting the shipping method
#
# @param skip_authentication [Boolean] default: false
#   verify if need create an account
#
def navigate_to_payment(skip_authentication = false)
  # set valid Cielo config
  Spree::CieloConfig.test_mode = true
  Spree::CieloConfig.afiliation_key = '12345'
  Spree::CieloConfig.token = 'abc1234'
  Spree::CieloConfig.credit_cards = {'visa' => 10}
  Spree::CieloConfig.minimum_value = '5.0'

  # add mug to cart
  visit spree.root_path
  click_link mug.name
  click_button 'add-to-cart-button'
  click_button 'Checkout'

  if !skip_authentication
    fill_in 'spree_user_email', with: 'test@example.com'
    fill_in 'spree_user_password', with: 'spree123'
    fill_in 'spree_user_password_confirmation', with: 'spree123'
    click_on 'Create'
  end

  # set address
  address = 'order_bill_address_attributes'
  fill_in "#{address}_firstname", with: 'Ryan'
  fill_in "#{address}_lastname", with: 'Bigg'
  fill_in "#{address}_address1", with: '143 Swan Street'
  fill_in "#{address}_city", with: 'Richmond'
  select 'United States of America', from: "#{address}_country_id"
  select 'Alabama', from: "#{address}_state_id"
  fill_in "#{address}_zipcode", with: '12345'
  fill_in "#{address}_phone", with: '(555) 555-5555'
  # confirm address
  click_button 'Save and Continue'

  # confirm shipping method
  click_button 'Save and Continue'
end

# Set the credit card data to checkout page
def fill_credit_card_data
  fill_in 'Name on card', with: 'Spree Commerce'
  # set the fields with javascript
  page.execute_script "$('#cielo_card_number').val('4111111111111111');"
  page.execute_script "$('#card_expiry').val('04 / 20');"
  # javascript para executar a funcao que faz a requisicao a api
  # trazendo o numero de parcelas de acordo com o tipo de cartao
  page.execute_script "obj = new window.CieloCredit({param_prefix: 'payment_source[1]', total_order: '10.0', currency: 'usd'}); obj.setCreditCard();"
  fill_in 'Card Code', with: '123'
  choose '1x of $10.00'
  # confirm payment method
  click_button 'Save and Continue'
end

def fill_debt_card_data
  fill_in 'Name on card', with: 'Spree Commerce'
  page.execute_script "$('#cielo_debt_number').val('4111111111111111');"
  page.execute_script "$('#cielo_debt_expiry').val('04 / 20');"
  fill_in 'Card Code', with: '123'
  page.execute_script "obj = new window.CieloDebt({payment_method_id: '1'}); obj.setCreditCard();"
  # confirm payment method
  click_button 'Authorize'
end

def stub_cielo_request(filename = 'authorize_success')
  response = JSON.parse File.read("spec/fixtures/cielo_returns/#{filename}.json"), symbolize_names: true
  allow_any_instance_of(Cielo::Transaction).to receive(:create!).and_return(response)
end