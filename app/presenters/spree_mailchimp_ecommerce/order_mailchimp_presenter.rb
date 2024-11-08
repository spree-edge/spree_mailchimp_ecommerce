# frozen_string_literal: true

module SpreeMailchimpEcommerce
  class OrderMailchimpPresenter
    include OrderMethods

    attr_reader :order

    def initialize(order)
      @order = order
      raise "Order in wrong state" unless order.completed?
    end

    def json
      order_json.merge(campaign_id).merge(promotions).merge(
        {
          processed_at_foreign: order.completed_at.in_time_zone("UTC").iso8601,
          discount_total: - order.promo_total || 0.0,
          tax_total: order.additional_tax_total || 0.0,
          shipping_total: order.shipment_total || 0.0,
          shipping_address: order_address(order.shipping_address),
          billing_address: order_address(order.billing_address),
          order_url: ::Spree::Core::Engine.routes.url_helpers.order_url(order, host: Rails.application.routes.default_url_options[:host])
        }.as_json
      )
    end

    private

    def campaign_id
      return {} unless order.mailchimp_campaign_id

      { campaign_id: order.mailchimp_campaign_id }.as_json
    end

    def promotions
      return {} unless promotions_list.any?

      promos = promotions_list.map do |p|
        rule = PromoRuleMailchimpPresenter.new(p).json
        {
          code: p.code || "promotion:#{p.id}",
          amount_discounted: rule['amount'],
          type: rule['type']
        }
      end
      { promos: promos }
    end

    def promotions_list
      order.all_adjustments.eligible.nonzero.promotion.map(&:source).compact.map(&:promotion).uniq
    end

    def user
      if order.user
        UserMailchimpPresenter.new(order.user).json
      elsif order.email
        {
          id: Digest::MD5.hexdigest(order.email.downcase),
          first_name: order.bill_address&.firstname || "",
          last_name: order.bill_address&.last_name || "",
          email_address: order.email || "",
          opt_in_status: false,
          address: customer_address(order.shipping_address)
        }
      end
    end

    def customer_address(address)
      return {} unless address

      AddressMailchimpPresenter.new(address).json
    end

    def order_address(address)
      customer_address(address).merge({ name: address&.full_name }.as_json)
    end
  end
end
