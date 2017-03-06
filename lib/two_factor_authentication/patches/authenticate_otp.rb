# Heavily based on(I copied it entirely :D) https://github.com/AsteriskLabs 's patch
module TwoFactorAuthentication::Patches
  # patch Sessions controller to check that the OTP is accurate
  module AuthenticateOTP
    extend ActiveSupport::Concern
    included do
    # here the patch

      alias_method :create_original, :create

      define_method :checkotp_resource_path_name do |resource, id|
        name = resource.class.name.singularize.underscore
        name = name.split('/').last
        "#{name}_two_factor_authentication_path(sfa_temp:'#{id}')"
      end

      define_method :create do

        resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")

        if resource.respond_to?(:need_two_factor_authentication?) and resource.require_token?(cookies.signed[TwoFactorAuthentication::REMEMBER_TFA_COOKIE_NAME])
          tmpid = resource.assign_tmp
          resource.send_new_otp unless resource.totp_enabled?
          warden.logout(resource_name)

          #we head back into the two factor authentication controller with the temporary id
          #Because the model used for google auth may not always be the same, and may be a sub-model, the eval will evaluate the appropriate path name
          #This change addresses https://github.com/AsteriskLabs/devise_google_authenticator/issues/7
          respond_with resource, :location => eval(checkotp_resource_path_name(resource, tmpid))

        else
          set_flash_message(:notice, :signed_in) if is_flashing_format?
          sign_in(resource_name, resource)
          respond_with resource, :location => after_sign_in_path_for(resource)
        end

      end
    end
  end
end