require 'spree_core'
require 'spree_zaez_cielo/engine'
require 'cielo'

Spree::PermittedAttributes.payment_attributes.push :portions
