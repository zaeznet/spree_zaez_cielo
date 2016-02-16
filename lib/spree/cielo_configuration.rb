class Spree::CieloConfiguration < Spree::Preferences::Configuration
  preference :afiliation_key,      :string                     # afiliation key
  preference :token,               :string                     # token
  preference :test_mode,           :boolean, default: false    # enable test mode
  preference :minimum_value,       :string,  default: '5.0'    # minimum value per portion (minimum is 5.00)
  preference :tax_value,           :string,  default: '0.0'    # tax value per month
  preference :portion_without_tax, :integer, default: 1        # number of portions without tax
  preference :product_value,       :string,  default: '2'      # product value (1: a vista, 2: a loja, 3: operadora, A: debito)
  preference :soft_descriptor,     :string,  default: ''       # soft descriptor (only for Visa and Mastercard)
  preference :generate_token,      :boolean, default: true     # if is enable, generate a token to future transactions
  preference :debt_cards,          :array,   default: []       # debt cards enables (visa or mastercard)
  preference :credit_cards,        :hash,    default: {}       # credit cards enables (and your quantities of portions) exe. {'visa' => 12}

  # Calculates the portions of credit card type
  # based on Cielo configuration
  #
  # @param order [Spree::Order]
  # @param cc_type [String]
  #
  # @return [Array]
  #
  def calculate_portions(order, cc_type)
    amount = order.total.to_f
    ret = []
    if preferred_credit_cards.has_key? cc_type
      portions_number = preferred_credit_cards[cc_type]
      minimum_value = preferred_minimum_value.to_f
      tax = preferred_tax_value.to_f

      ret.push({portion: 1, value: amount, total: amount, tax_message: :cielo_without_tax})

      (2..portions_number).each do |number|
        if tax <= 0 or number <= preferred_portion_without_tax
          value = amount / number
          tax_message = :cielo_without_tax
        else
          value = (amount * ((1 + tax / 100) ** number)) / number
          tax_message = :cielo_with_tax
        end

        if value >= minimum_value
          value_total = value * number
          ret.push({portion: number, value: value, total: value_total, tax_message: tax_message})
        end
      end
    end
    ret
  end

  # Calculate the value of the portion based on Cielo configuration
  # (verify if the portion has tax)
  #
  # @param order [Spree::Order]
  # @param portion [Integer]
  #
  # @return [Float]
  #
  def calculate_portion_value(order, portion)
    amount = order.total.to_f
    amount = amount / 100 if amount.is_a? Integer
    tax = preferred_tax_value.to_f

    if tax <= 0 or portion <= preferred_portion_without_tax
      value = amount / portion
    else
      value = (amount * ((1 + tax / 100) ** portion)) / portion
    end
    value
  end
end