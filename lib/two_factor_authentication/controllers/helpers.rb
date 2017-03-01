module TwoFactorAuthentication
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      included do
        before_action :handle_two_factor_authentication
      end

      private

      def handle_two_factor_authentication
        unless devise_controller?
            if signed_in?(resource_name) and warden.session(resource_name)[TwoFactorAuthentication::NEED_AUTHENTICATION]
              handle_failed_second_factor(resource_name)
            end
        end
      end

      def handle_failed_second_factor(scope)
        if request.format.present? and request.format.html?
          session["#{scope}_return_to"] = request.original_fullpath if request.get?
          redirect_to two_factor_authentication_path_for(scope)
        else
          render nothing: true, status: :unauthorized
        end
      end

      def two_factor_authentication_path_for(resource_or_scope = nil)
        scope = Devise::Mapping.find_scope!(resource_or_scope)
        change_path = "#{scope}_two_factor_authentication_path"
        send(change_path)
      end

    end
  end
end

module Devise
  module Controllers
    module Helpers
      def is_fully_authenticated?
        !session["warden.user.user.session"].try(:[], TwoFactorAuthentication::NEED_AUTHENTICATION)
      end
    end
  end
end
