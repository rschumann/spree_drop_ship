class Spree::DropShipOrder < ActiveRecord::Base

  #==========================================
  # Associations

  belongs_to :order
  belongs_to :supplier

  has_many :drop_ship_line_items, dependent: :destroy
  has_many :line_item_adjustments, through: :line_items, source: :adjustments
  has_many :line_items, through: :drop_ship_line_items
  has_many :inventory_units, through: :line_items
  has_many :return_authorizations, through: :order
  has_many :shipment_adjustments, through: :shipments, source: :adjustments
  has_many :shipments, through: :inventory_units
  # order.shipments.includes(:stock_location).where('spree_stock_locations.supplier_id = ?', self.supplier_id).references(:stock_location)
  # has_many :shipments,
  #   -> { joins(:stock_location => :supplier) },
  #   through: :order do
  #     def states
  #       pluck(:state).uniq
  #     end
  #   end

  has_many :stock_locations, through: :supplier
  has_many :users, class_name: Spree.user_class.to_s, through: :supplier

  has_one :user, through: :order

  #==========================================
  # Validations

  validates :commission, presence: true
  validates :order_id, presence: true
  validates :supplier_id, presence: true

  #==========================================
  # Callbacks

  before_save :update_totals

  #==========================================
  # State Machine

  state_machine :initial => :active do

    after_transition :on => :deliver, :do => :perform_delivery
    after_transition :on => :confirm, :do => :perform_confirmation
    after_transition :on => :complete, :do => :perform_complete

    event :deliver do
      transition [ :active, :delivered ] => :delivered
    end

    event :confirm do
      transition [ :active, :delivered ] => :confirmed
    end

    event :complete do
      transition [ :active, :delivered, :confirmed ] => :completed
    end

  end

  #==========================================
  # Instance Methods

  delegate :adjustments, to: :order
  delegate :approved_at, to: :order
  delegate :approved?, to: :order
  delegate :approver, to: :order
  delegate :bill_address, to: :order
  delegate :checkout_steps, to: :order
  delegate :currency, to: :order

  # Don't allow drop ship orders to be destroyed
  def destroy
    false
  end

  delegate :digital?, to: :order

  def display_item_total
    Spree::Money.new(self.item_total, { currency: currency })
  end

  def display_ship_total
    Spree::Money.new self.ship_total, currency: currency
  end

  def display_tax_total
    Spree::Money.new self.tax_total, currency: currency
  end

  def display_total
    Spree::Money.new(self.total, { currency: currency })
  end

  delegate :email, to: :order
  delegate :find_line_item_by_variant, to: :order
  delegate :is_risky?, to: :order

  def item_total
    line_items.map(&:final_amount).sum
  end

  alias_method :number, :id

  delegate :payment_state, to: :order

  delegate :payments, to: :order

  def promo_total
    line_items.sum(:promo_total)
  end

  delegate :ship_address, to: :order

  def ship_total
    shipments.map(&:final_price).sum
  end

  def shipment_state
    shipment_count = shipments.size
    return 'pending' if shipment_count == 0 or shipment_count == shipments.pending.size
    return 'ready'   if shipment_count == shipments.ready.size
    return 'shipped' if shipment_count == shipments.shipped.size
    return 'partial'
  end

  # def shipments
  #   order.
  #     shipments.
  #     includes(:stock_location).
  #     where(spree_stock_locations: {supplier_id: self.supplier_id}).
  #     references(:stock_location)
  # end

  delegate :special_instructions, to: :order

  def tax_total
    line_items.map(&:tax_total).sum
  end

  #==========================================
  # Private Methods

  private

    def perform_complete # :nodoc:
      self.update_attribute(:completed_at, Time.now)
    end

    def perform_confirmation # :nodoc:
      self.update_attribute(:confirmed_at, Time.now)
    end

    def perform_delivery # :nodoc:
      self.update_attribute(:sent_at, Time.now)
      if SpreeDropShip::Config[:send_supplier_email]
        Spree::Core::MailMethod.new.deliver!(Spree::DropShipOrderMailer.supplier_order(self.id))
      end
    end

    def update_commission
      self.commission = (self.total * self.supplier.commission_percentage / 100) + self.supplier.commission_flat_rate
    end

    # Updates the drop ship order's total by getting the shipment totals.
    def update_totals
      # puts self.line_items.inspect
      # self.line_items.each do |li|
      #   puts li.final_amount.to_f
      # end
      # puts self.shipments.inspect
      # self.shipments.each do |shipment|
      #   puts shipment.cost.to_f
      #   puts shipment.promo_total.to_f
      #   puts shipment.discounted_cost.to_f
      #   puts shipment.item_cost.to_f
      #   puts shipment.final_price.to_f
      #   puts shipment.tax_total.to_f
      #   puts shipment.shipping_rates.inspect
      #   shipment.shipping_rates.each do |rate|
      #     puts rate.inspect
      #     puts rate.cost.to_f
      #   end
      #   puts 'selected rate'
      #   puts shipment.selected_shipping_rate.inspect
      #   puts shipment.selected_shipping_rate.cost.to_f
      # end
      # self.shipments.first.refresh_rates
      # self.shipments.reload.first.shipping_rates.each do |rate|
      #   puts rate.inspect
      #   puts rate.cost.to_f
      # end
      # puts "refresh rates: #{self.shipments.first.selected_shipping_rate.cost.to_f}"
      # puts "shipments: #{self.shipments.map(&:final_price).sum.to_f} - line_items: #{self.line_items.map(&:final_amount).sum.to_f}"

      self.additional_tax_total = self.line_items.sum(:additional_tax_total) + self.shipments.sum(:additional_tax_total)
      self.included_tax_total   = self.line_items.sum(:included_tax_total)   + self.shipments.sum(:included_tax_total)
      self.total                = self.shipments.map(&:final_price).sum      + self.line_items.map(&:final_amount).sum
      update_commission
      puts "Totals: #{self.inspect} - #{self.additional_tax_total.to_f} - #{self.included_tax_total.to_f} - #{self.total.to_f}"
    end

end
