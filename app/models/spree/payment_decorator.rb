module Spree
  Payment.class_eval do

    # TODO: This is deprecated. Maybe do shipment? Need to figure out how to leverage partial capturing best.
    # belongs_to :drop_ship_order

  end
end
