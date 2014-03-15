class AddFieldForPersistingTotals < ActiveRecord::Migration
  def change
    add_column :spree_drop_ship_orders, :additional_tax_total, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_drop_ship_orders, :included_tax_total, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
