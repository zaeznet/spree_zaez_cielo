module ControllerHacks
  extend ActiveSupport::Concern

  included do
    routes { Spree::Core::Engine.routes }
  end

  def api_get(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "GET")
  end

  def api_process(action, params={}, session=nil, flash=nil, method="get")
    scoping = respond_to?(:resource_scoping) ? resource_scoping : {}
    process(action, method, params.merge(scoping).reverse_merge!(:format => :json), session, flash)
  end
end

RSpec.configure do |config|
  config.include ControllerHacks, type: :controller
end