module Spree
  class SupplierAbility
    include CanCan::Ability

    def initialize(user)
      user ||= Spree.user_class.new

      if user.supplier
        if defined?(Spree::Digital)
          can [:admin, :manage], Spree::Digital, variant: { product: { supplier_id: user.supplier_id } }
          can :create, Spree::Digital
        end
        can [:admin, :manage], Spree::Image do |image|
          image.viewable.product.supplier_id == user.supplier_id
        end
        can :create, Spree::Image
        if defined?(Spree::GroupPrice)
          can [:admin, :manage], Spree::GroupPrice, variant: { product: { supplier_id: user.supplier_id } }
        end
        if defined?(Spree::Relation)
          can [:admin, :manage], Spree::Relation, relatable: { supplier_id: user.supplier_id }
        end
        can [:admin, :manage, :stock], Spree::Product, supplier_id: user.supplier_id
        can :create, Spree::Product
        can [:admin, :manage], Spree::ProductProperty, product: { supplier_id: user.supplier_id }
        can [:admin, :index, :read], Spree::Property
        can [:admin, :read], Spree::Prototype
        can [:admin, :manage, :read, :ready, :ship], Spree::Shipment, order: { state: 'complete' }, stock_location: { supplier_id: user.supplier_id }
        can [:admin, :create, :update], :stock_items
        can [:admin, :manage], Spree::StockItem, variant: { product: { supplier_id: user.supplier_id } }
        can [:admin, :manage], Spree::StockLocation, supplier_id: user.supplier_id
        can :create, Spree::StockLocation
        can [:admin, :manage], Spree::StockMovement, stock_item: { variant: { product: { supplier_id: user.supplier_id } } }
        can :create, Spree::StockMovement
        can [:admin, :update], Spree::Supplier, id: user.supplier_id
        can [:admin, :manage], Spree::Variant, product: { supplier_id: user.supplier_id }
      end

      if SpreeDropShip::Config[:allow_signup]
        can :create, Spree::Supplier
      end

      if defined?(Ckeditor)
        can :access, :ckeditor

        can :create, Ckeditor::AttachmentFile
        can [:read, :index, :destroy], Ckeditor::AttachmentFile, supplier_id: user.supplier_id

        can :create, Ckeditor::Picture
        can [:read, :index, :destroy], Ckeditor::Picture, supplier_id: user.supplier_id
      end

    end
  end
end
