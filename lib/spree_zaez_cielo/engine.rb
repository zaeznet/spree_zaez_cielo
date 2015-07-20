module SpreeZaezCielo
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_zaez_cielo'

    initializer 'spree.zaez_cielo.preferences', :after => :load_config_initializers do |app|
      # require file with the preferences of the Billet
      require 'spree/cielo_configuration'
      Spree::CieloConfig = Spree::CieloConfiguration.new

      # initialize the Cielo settings
      Cielo.setup do |config|
        config.environment = Spree::CieloConfig.test_mode ? :test : :production
        config.numero_afiliacao = Spree::CieloConfig.afiliation_key
        config.chave_acesso = Spree::CieloConfig.token
      end
    end

    initializer 'spree.zaez_cielo.payment_methods', :after => 'spree.register.payment_methods' do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::CieloCredit
      app.config.spree.payment_methods << Spree::PaymentMethod::CieloDebt
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
