module Spree
  class PaymentMethod::CieloDebt < PaymentMethod

    def payment_source_class
      Spree::CreditCard
    end

    # Creates the transaction to Cielo
    # and return the url of authentication
    #
    # @author Isabella Santos
    #
    # @param amount [Integer]
    #   amount of the payment
    # @param source [Spree::CreditCard]
    #   source of the payment (object which contains the credit card information)
    #
    # @return [Hash]
    #
    def create(amount, source)
      cc_type = source.cc_type
      cc_type = 'mastercard' if cc_type == 'master'

      return_url = Spree::Store.current.url
      return_url << Spree::Core::Engine.routes.url_helpers.cielo_debt_confirm_path(source.id, self.id)

      year = source.year.to_s.rjust(4, '0')
      month = source.month.to_s.rjust(2, '0')

      params = { numero: source.id,
        valor: amount,
        moeda: '986',
        bandeira: cc_type,
        parcelas: '1',
        cartao_numero: source.number,
        :'url-retorno' => return_url,
        cartao_validade: "#{year}#{month}",
        cartao_seguranca: source.verification_value,
        cartao_portador: source.name,
        autorizar: '2',
        produto: 'A',
        capturar: 'true'
      }

      params[:'soft-descriptor'] = Spree::CieloConfig.soft_descriptor if Spree::CieloConfig.soft_descriptor.present?

      transaction = Cielo::Transaction.new
      ret = transaction.create!(params, :store)

      if ret[:transacao][:status] == '0'
        {url_auth: ret[:transacao][:'url-autenticacao'], tid: ret[:transacao][:tid]}
      else
        {error: Spree.t('cielo.messages.authorize_fail')}
      end
    rescue
      if !ret.nil? and ret.has_key? :erro
        if ret[:erro][:codigo] == '001'
          {error: Spree.t('cielo.messages.invalid_message')}
        else
          {error: "Cielo: #{ret[:erro][:codigo]} - #{ret[:erro][:mensagem]}"}
        end
      else
        {error: Spree.t('cielo.messages.create_rescue')}
      end
    end

    # Purchases the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @param _amount [Integer]
    #   amount of the payment (not used for debt)
    # @param source [Spree::CreditCard]
    #   source of the payment (object which contains the credit card information)
    # @param _gateway_options [Hash]
    #   collection of information of the payment (not used for debt)
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def purchase(_amount, source, _gateway_options)
      transaction = Cielo::Transaction.new
      ret = transaction.verify!(source.gateway_payment_profile_id)

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
    # @param _amount [Integer]
    #   amount of the payment (not used for debt)
    # @param source [Spree::CreditCard]
    #   source of the payment (object which contains the credit card information)
    # @param _gateway_options [Hash]
    #   collection of information of the payment (not used for debt)
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def authorize(_amount, source, _gateway_options)
      transaction = Cielo::Transaction.new
      ret = transaction.verify!(source.gateway_payment_profile_id)

      if ret[:transacao][:status] == '4'
        ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.authorize_success'), {}, authorization: ret[:transacao][:tid])
      else
        ActiveMerchant::Billing::Response.new(false, Spree.t('cielo.messages.authorize_fail'), {}, authorization: ret[:transacao][:tid])
      end
    rescue
      verify_error 'authorize', ret
    end

    # Authorizes the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @param _amount [Integer]
    #   amount of the payment (not used for debt)
    # @param response_code [String]
    #   response code of transaction
    # @param _gateway_options [Hash]
    #   collection of information of the payment (not used for debt)
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

    # Authorizes the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @param response_code [String]
    #   response code of transaction
    # @param _gateway_options [Hash]
    #   collection of information of the payment (not used for debt)
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

    # Cancel the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def cancel(response_code)
      transaction = Cielo::Transaction.new
      response = transaction.verify!(response_code)

      if response[:transacao][:status] == '4' or response[:transacao][:status] == '6'
        response_cancel = transaction.cancel!(response_code)
        if response_cancel[:transacao].present?
          ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.cancel_success'), {}, authorization: response_cancel[:transacao][:tid])
        else
          verify_error 'cancel', response_cancel
        end
      else
        ActiveMerchant::Billing::Response.new(true, Spree.t('cielo.messages.cancel_success'), {}, authorization: response[:transacao][:tid])
      end
    rescue
      verify_error 'cancel', response
    end

    def auto_capture?
      true
    end

    private

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
        ActiveMerchant::Billing::Response.new(false, "Cielo: #{ret[:erro][:codigo]} - #{ret[:erro][:mensagem]}", {}, {})
      else
        ActiveMerchant::Billing::Response.new(false, Spree.t("cielo.messages.#{action}_rescue"), {}, {})
      end
    end
  end
end