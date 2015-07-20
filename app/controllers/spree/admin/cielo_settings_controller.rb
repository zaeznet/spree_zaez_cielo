class Spree::Admin::CieloSettingsController < Spree::Admin::BaseController

  def edit
    @config = Spree::CieloConfiguration.new
    @credit_cards = [:visa, :master, :diners, :discover, :elo, :amex, :jcb]
    @debt_cards = [:visa, :master]
  end

  def update
    config = Spree::CieloConfiguration.new

    params.each do |name, value|
      next if !config.has_preference?(name) or name == 'credit_cards'
      config[name] = value
    end

    config.test_mode = false unless params.include?(:test_mode)

    # set the values to Cielo object
    Cielo.environment = config.test_mode ? :test : :production
    Cielo.numero_afiliacao = config.afiliation_key
    Cielo.chave_acesso = config.token
    
    # set the portion of the credit cards
    if params[:credit_cards].present?
      cards = {}
      params[:credit_cards].each do |card|
        if card.has_key?('state')
          cards[card['name']] = card['portion'].to_i
        end
      end
      config.credit_cards = cards
    end

    flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:cielo_settings))
    redirect_to edit_admin_cielo_settings_path
  end
end