module SpreeMailchimpEcommerce
  module Spree
    module LineItemDecorator
      def self.prepended(base)
        base.after_update :update_mailchimp_cart
        base.after_create :handle_cart
        base.after_destroy :delete_line_item
      end

      def handle_cart
        return unless order.user

        # sync product to Mailchimp
        product = self.product
        create_mailchimp_product_if_needed(product)

        # Create or update Mailchimp cart
        order.mailchimp_cart_created ? update_mailchimp_cart : order.create_mailchimp_cart
      end

      def mailchimp_line_item
        ::SpreeMailchimpEcommerce::LineMailchimpPresenter.new(self).json
      end

      private

      def update_mailchimp_cart
        order.update_mailchimp_cart
      end

      def delete_line_item
        ::SpreeMailchimpEcommerce::DeleteLineItemJob.perform_later(id, order_id, order.number)
      end

      def create_mailchimp_product_if_needed(product)
        return unless product.mailchimp_product
        mailchimp_product = ::SpreeMailchimpEcommerce::ProductMailchimpPresenter.new(product).json
        ::SpreeMailchimpEcommerce::CreateProductJob.perform_later(mailchimp_product)
      end
    end
  end
end
Spree::LineItem.prepend(SpreeMailchimpEcommerce::Spree::LineItemDecorator)
