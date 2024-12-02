module Spree
  module Admin
    module MainMenu
      module DefaultConfigurationBuilderDecorator
        def add_settings_section(root)
          super

          section = root.items.find { |s| s.key == 'settings' }
          return unless section

          section.items << ItemBuilder.new('mailchimp_settings', admin_mailchimp_settings_path).
            with_manage_ability_check(MailchimpSetting).
            with_match_path('/mailchimp_settings').
            build
        end
      end
    end
  end
end

Spree::Admin::MainMenu::DefaultConfigurationBuilder.prepend(
  Spree::Admin::MainMenu::DefaultConfigurationBuilderDecorator
)
