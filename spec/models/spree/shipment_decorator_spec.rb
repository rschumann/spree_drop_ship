require 'spec_helper'

describe Spree::Shipment do

  describe 'Scopes' do

    it '#by_supplier' do
      supplier = create(:supplier)
      stock_location_1 = supplier.stock_locations.first
      stock_location_2 = create(:stock_location, supplier: supplier)
      shipment_1 = create(:shipment)
      shipment_2 = create(:shipment, stock_location: stock_location_1)
      shipment_3 = create(:shipment)
      shipment_4 = create(:shipment, stock_location: stock_location_2)
      shipment_5 = create(:shipment)
      shipment_6 = create(:shipment, stock_location: stock_location_1)

      expect(subject.class.by_supplier(supplier.id)).to match_array([shipment_2, shipment_4, shipment_6])
    end

  end

  describe '#after_ship' do

    it 'should capture payment if balance due' do
      pending 'TODO make it so!'
    end

    it 'should track commission for shipment' do
      pending 'TODO make it so!'
    end

  end

end
