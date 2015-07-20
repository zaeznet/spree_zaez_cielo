module Spree
  Payment::GatewayOptions.class_eval do
    def portions
      @payment.portions
    end

    alias_method :hash_methods_old, :hash_methods
    def hash_methods
      ret = hash_methods_old
      ret << :portions
      ret
    end
  end
end