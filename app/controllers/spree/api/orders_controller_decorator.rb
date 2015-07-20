module Spree
  Api::OrdersController.class_eval do
    skip_before_action :authenticate_user, only: [:apply_coupon_code, :portions]

    # Calculates the quantity of portions the order can have
    # based on amount and credit card type
    #
    def portions
      if params[:credit_card_id].present?
        credit_card = Spree::CreditCard.find params[:credit_card_id]
        @cc_type = credit_card.cc_type
        @cc_type = 'amex' if @cc_type == 'american_express'
        @cc_type = 'master' if @cc_type == 'mastercard'
      else
        @cc_type = params[:cc_type]
      end
      if Spree::CieloConfig.credit_cards.has_key?(@cc_type)
        @tax = Spree::CieloConfig[:tax_value].to_f

        # set the prefix if exists
        @prefix = params[:prefix].present? ? params[:prefix] : nil

        @portions = Spree::CieloConfig.calculate_portions @order.total, @cc_type
        @portions.each do |item|
          item[:total] = Spree::Money.new(item[:total], {currency: @order.currency}).to_html
          item[:value] = Spree::Money.new(item[:value], {currency: @order.currency}).to_html
        end

        if Spree::CieloConfig[:portion_without_tax] < @portions.size and @tax > 0
          @show_tax_value = true
        else
          @show_tax_value = false
        end

        @cc_type = 'american_express' if @cc_type == 'amex'

        respond_to do |format|
          format.html { render( :action => 'portions.html.erb') }
          format.json do
            render json: @portions.to_json
          end
        end
      else
        respond_to do |format|
          format.html do
            supported_cards = Spree::CieloConfig.credit_cards.keys.collect { |i| "<li>#{Spree.t("cielo_#{i}")}</li>" }
            ret = "<label style='font-weight: normal;'>#{Spree.t('errors.cielo_card_fail')}<ul>#{supported_cards.join('')}</ul></label>"
            render status: 500, inline: ret.html_safe
          end
          format.json do
            render 'spree/api/errors/unavailable_credit_card', status: 500
          end
        end
      end
    end
  end
end