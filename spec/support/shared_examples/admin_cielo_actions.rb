shared_examples_for 'admin cielo actions' do
  context 'capture the payment' do
    it 'should capture the payment', js: true do
      response = JSON.parse File.read('spec/fixtures/cielo_returns/capture_success.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Transaction).to receive(:catch!).and_return(response)

      visit spree.admin_order_payments_path payment.order
      click_icon :capture

      expect(page).to have_text 'Payment Updated'
      within_row(1) do
        expect(column_text(6)).to eq 'completed'
      end
    end

    it 'should show an error message when try capture and fail', js: true do
      response = JSON.parse File.read('spec/fixtures/cielo_returns/capture_error.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Transaction).to receive(:catch!).and_return(response)

      visit spree.admin_order_payments_path payment.order
      click_icon :capture

      expect(page).to have_text "Cielo: 030 - O status 'Nao autorizada' não permite captura."
      within_row(1) do
        expect(column_text(6)).to eq 'failed'
      end
    end
  end

  context 'void the payment' do
    it 'should void the payment', js: true do
      response = JSON.parse File.read('spec/fixtures/cielo_returns/void_success.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Transaction).to receive(:cancel!).and_return(response)

      visit spree.admin_order_payments_path payment.order
      click_icon :void

      expect(page).to have_text 'Payment Updated'
      within_row(1) do
        expect(column_text(6)).to eq 'void'
      end
    end

    it 'should show an error message when try void and fail', js: true do
      response = JSON.parse File.read('spec/fixtures/cielo_returns/void_error.json'), symbolize_names: true
      allow_any_instance_of(Cielo::Transaction).to receive(:cancel!).and_return(response)

      visit spree.admin_order_payments_path payment.order
      click_icon :void

      expect(page).to have_text "Cielo: 041 - O status 'Nao autorizada' não permite cancelamento."
      within_row(1) do
        expect(column_text(6)).to eq 'checkout'
      end
    end
  end
end