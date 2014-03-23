Spree::Shipment.class_eval do

  scope :by_supplier, -> (supplier_id) { joins(:stock_location).where(spree_stock_locations: { supplier_id: supplier_id }) }

  delegate :supplier, to: :stock_location
  delegate :supplier?, to: :stock_location

  private

  durably_decorate :after_ship, mode: 'soft', sha: 'd0665a43fd8805f9fd1958b988e35f12f4cee376' do
    original_after_ship

    if supplier?
      update_commission
    end
  end

  def update_commission
    update_column :supplier_commission, ((self.final_price * self.supplier.commission_percentage / 100) + self.supplier.commission_flat_rate)
  end

end
