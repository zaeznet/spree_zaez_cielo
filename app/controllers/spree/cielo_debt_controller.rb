module Spree
  class CieloDebtController < Spree::StoreController

    before_filter :set_credit_card, only: [:confirm]
    skip_before_action :verify_authenticity_token, only: [:confirm]

    def create
      if current_order.guest_token != params[:guest_token]
        render status: 500, json: {error: Spree.t('errors.invalid_guest_token')} and return
      end
      if Spree::CieloConfig.debt_cards.include?(params[:source][:cc_type])
        credit_card = Spree::CreditCard.new(credit_card_params)
        if credit_card.save
          payment_method = Spree::PaymentMethod.find params[:payment_method_id]
          amount = current_order.display_total.money.cents
          response = payment_method.create amount, credit_card

          if response.has_key? :url_auth
            credit_card.update_attributes(gateway_payment_profile_id: response[:tid])
            render json: response
          else
            credit_card.destroy
            render status: 500, json: response
          end
        else
          errors = credit_card.errors.full_messages.join('<br/>')
          render status: 500, json: {error: errors}
        end
      else
        supported_cards = Spree::CieloConfig.debt_cards.collect { |i| "<li>#{Spree.t("cielo_#{i}")}</li>" }
        message = "<label style='font-weight: normal;'>#{Spree.t('errors.cielo_card_fail')}<ul>#{supported_cards.join('')}</ul></label>"
        render status: 500, inline: message.html_safe
      end
    end

    def confirm
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.payments.create!({
        source: @credit_card,
        amount: order.total,
        payment_method_id: @payment_method.id
      })
      order.temporary_credit_card = true
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to order_path(order)
      else
        flash[:error] = order.errors.full_messages.join("\n")
        redirect_to checkout_state_path(order.state) and return
      end
    end

    private

    def set_credit_card
      @credit_card = Spree::CreditCard.find params[:credit_card_id]
      @payment_method = Spree::PaymentMethod.find params[:payment_method_id]
    end

    def credit_card_params
      params.require(:source).permit(permitted_source_attributes)
    end
  end
end