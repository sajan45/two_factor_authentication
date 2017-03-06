module TwoFactorAuthentication
  module Patches
    autoload :AuthenticateOTP, 'two_factor_authentication/patches/authenticate_otp'

    class << self
      def apply
        Devise::SessionsController.send(:include, Patches::AuthenticateOTP)
      end
    end
  end
end