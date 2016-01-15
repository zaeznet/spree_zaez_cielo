module Spree
  class PaymentMethod::CieloCredit < PaymentMethod

    def payment_source_class
      Spree::CreditCard
    end

    # Purchases the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def purchase(amount, source, gateway_options)
      if gateway_options[:portions].nil?
        return ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.invalid_portions'), {}, {})
      end

      total_value = update_payment_amount amount, source, gateway_options
      total_value.delete!('.')
      default_params = {
          parcelas: gateway_options[:portions],
          capturar: 'true'
      }

      if source.gateway_customer_profile_id.present?
        params = { token: CGI.escape(source.gateway_customer_profile_id) }
      elsif Spree::CieloConfig.generate_token
        params = generate_token source

        if params[:token].nil?
          params = {
              cartao_numero: source.number,
              cartao_validade: "#{source.year}#{source.month}",
              cartao_seguranca: source.verification_value,
              cartao_portador: source.name
          }
        end
      else
        params = {
            cartao_numero: source.number,
            cartao_validade: "#{source.year}#{source.month}",
            cartao_seguranca: source.verification_value,
            cartao_portador: source.name
        }
      end
      transaction_params = mount_params(total_value, source, params.merge!(default_params))

      transaction = Cielo::Transaction.new
      ret = transaction.create!(transaction_params, :store)

      if ret[:transacao][:status] == '6'
        ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.purchase_success'), {}, authorization: ret[:transacao][:tid])
      else
        ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.purchase_fail'), {}, authorization: ret[:transacao][:tid])
      end
    rescue
      verify_error 'purchase', ret
    end

    # Authorizes the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def authorize(amount, source, gateway_options)
      if gateway_options[:portions].nil?
        return ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.invalid_portions'), {}, {})
      end

      total_value = update_payment_amount amount, source, gateway_options
      total_value.delete!('.')
      default_params = {
          parcelas: gateway_options[:portions],
          capturar: 'false'
      }

      if source.gateway_customer_profile_id.present?
        params = { token: CGI.escape(source.gateway_customer_profile_id) }
      elsif Spree::CieloConfig.generate_token
        params = generate_token source

        if params[:token].nil?
          params = {
              cartao_numero: source.number,
              cartao_validade: "#{source.year}#{source.month}",
              cartao_seguranca: source.verification_value,
              cartao_portador: source.name
          }
        end
      else
        params = {
            cartao_numero: source.number,
            cartao_validade: "#{source.year}#{source.month}",
            cartao_seguranca: source.verification_value,
            cartao_portador: source.name
        }
      end
      transaction_params = mount_params(total_value, source, params.merge!(default_params))

      transaction = Cielo::Transaction.new
      ret = transaction.create!(transaction_params, :store)

      if ret[:transacao][:status] == '4'
        ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.authorize_success'), {}, authorization: ret[:transacao][:tid])
      else
        ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.authorize_fail'), {}, authorization: ret[:transacao][:tid])
      end
    rescue
      verify_error 'authorize', ret
    end

    # Captures the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def capture(_amount, response_code, _gateway_options)
      transaction = Cielo::Transaction.new
      ret = transaction.catch!(response_code)

      ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.capture_success'), {}, authorization: ret[:transacao][:tid])
    rescue
      verify_error 'capture', ret
    end

    # Voids the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def void(response_code, _gateway_options)
      transaction = Cielo::Transaction.new
      ret = transaction.cancel!(response_code)

      ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.void_success'), {}, authorization: ret[:transacao][:tid])
    rescue
      verify_error 'void', ret
    end

    private

    # Returns the credit type formatted
    # Cielo and Spree accept different type for credit card
    #
    # @author Isabella Santos
    #
    # @param type [String]
    #
    # @return [String]
    #
    def format_cc_type type
      cc_type = type
      cc_type = 'mastercard' if cc_type == 'master'
      cc_type = 'amex' if cc_type == 'american_express'
      cc_type
    end

    # Generate and storage the token in the source object
    #
    # @author Isabella Santos
    #
    # @param credit_card [Spree::CreditCard]
    #
    # @return [Hash]
    #
    def generate_token credit_card
      token_request = Cielo::Token.new
      token_parameters = {
          cartao_numero: credit_card.number,
          cartao_validade: "#{credit_card.year}#{credit_card.month}",
          cartao_portador: credit_card.name
      }
      response = token_request.create! token_parameters, :store

      if response[:'retorno-token'][:token][:'dados-token'][:'codigo-token']
        token = response[:'retorno-token'][:token][:'dados-token'][:'codigo-token']
        credit_card.update_attributes(gateway_customer_profile_id: token)
        return { token: token }
      end
    rescue
      {}
    end

    # Returns the params to Cielo::Transaction
    #
    # @author Isabella Santos
    #
    # @param amount [String]
    #   value of the payment (with value in cents)
    # @param source [Spree::CreditCard]
    #   source of the payment (object CreditCard)
    # @param params [Hash]
    #   different attributes to params
    #
    # @return [Hash]
    #
    def mount_params(amount, source, params = {})
      cc_type = format_cc_type source.cc_type

      if params[:parcelas] > 1
        product_value = Spree::CieloConfig[:product_value]
      else
        product_value = '1'
      end

      if cc_type == 'visa' or cc_type == 'mastercard'
        params.merge!({:'soft-descriptor' => Spree::CieloConfig.soft_descriptor})
      end

      { numero: source.id,
        valor: amount,
        moeda: '986',
        bandeira: cc_type.downcase,
        :'url-retorno' => Spree::Store.current.url,
        autorizar: '3',
        produto: product_value
      }.merge!(params)
    end

    # Update the value of the payment with the tax of the portions
    #
    # @author Isabella Santos
    #
    # @param amount [Integer]
    # @param source [Spree::CreditCard]
    # @param gateway_options [Hash]
    #
    # @return [Integer]
    #
    def update_payment_amount(amount, source, gateway_options)
      if gateway_options[:portions] > 1
        portion_value = Spree::CieloConfig.calculate_portion_value amount, gateway_options[:portions]
        total_value = sprintf('%0.2f', portion_value * gateway_options[:portions])

        payment = Spree::Payment.find_by number: gateway_options[:order_id].split('-')[1]
        payment.update_attributes(amount: total_value)

        total_value
      else
        amount.to_s
      end
    end

    # Verify the error returning the ActiveMerchant::Billing object
    # with the message
    #
    # @param action [String]
    #   name of the action (purchase, capture, etc)
    # @param ret [Hash]
    #   return of Cielo
    #
    # @return [ActiveMerchant::Billing]
    #
    def verify_error action, ret
      if !ret.nil? and ret.has_key? :erro
        if ret[:erro][:codigo] == '001'
          ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.invalid_message'), {}, {})
        else
          ActiveMerchant::Billing::Response.new(false, "Cielo: #{ret[:erro][:codigo]} - #{ret[:erro][:mensagem]}", {}, {})
        end
      else
        ActiveMerchant::Billing::Response.new(false, Spree.t("cielo.messages.#{action}_rescue"), {}, {})
      end
    end
  end
end