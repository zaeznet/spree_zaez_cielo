module Spree
  FrontendHelper.class_eval do

    # Returns the credit cards with payment method CieloCredit
    #
    # @author Isabella Santos
    #
    # @param payment_sources [Spree::CreditCard::ActiveRecord_AssociationRelation]
    #
    # @return [Array]
    #
    def has_cielo_credit payment_sources
      has_cielo_credit = []
      payment_sources.each { |card| has_cielo_credit << card.id if card.payment_method.is_a? Spree::PaymentMethod::CieloCredit }
      has_cielo_credit.to_json
    end
  end
end