require 'devise/version'

class Devise::TwoFactorAuthenticationController < Devise::SessionsController
  prepend_before_action :authenticate_scope!
  before_action :prepare_and_validate

  include Devise::Controllers::Helpers

  def show
    @sfa_temp = params['sfa_temp']
    render :show
  end

  def update
    render :show and return if params[:code].nil?

    if params[:sfa_temp].present? && resource.present?
      if resource.authenticate_otp(params[:code])
        after_two_factor_success_for(resource)
      else
        after_two_factor_fail_for(resource)
      end
    end
    # 'else' case would have been handled in 'prepare_and_validate' callback
  end

  def resend_code
    if resource
      resource.send_new_otp
      @sfa_temp = resource.sf_auth_temp
      flash.now[:notice] = I18n.t('devise.two_factor_authentication.code_has_been_sent')
      render :show
    end
    # 'else' case would have been handled in 'prepare_and_validate' callback
  end

  private

  def after_two_factor_success_for(resource)
    set_remember_two_factor_cookie(resource)
    sign_in(resource_name, resource)
    flash[:notice] = I18n.t('devise.two_factor_authentication.success')
    resource.update_attributes(second_factor_attempts_count: 0, sf_auth_temp: nil)

    respond_with resource, :location => after_sign_in_path_for(resource)
  end

  def set_remember_two_factor_cookie(resource)
    expires_seconds = resource.class.remember_otp_session_for_seconds

    if expires_seconds && expires_seconds > 0
      cookies.signed[TwoFactorAuthentication::REMEMBER_TFA_COOKIE_NAME] = {
          value: "#{resource.class}-#{resource.public_send(Devise.second_factor_resource_id)}",
          secure: !(Rails.env.test? || Rails.env.development?),
          expires: expires_seconds.from_now
      }
    end
  end

  def after_two_factor_fail_for(resource)
    resource.second_factor_attempts_count += 1
    resource.save
    flash.now[:alert] = I18n.t('devise.two_factor_authentication.attempt_failed')

    if resource.max_login_attempts?
      sign_out(resource)
      render :max_login_attempts_reached
    else
      @sfa_temp = resource.sf_auth_temp
      render :show
    end
  end

  def authenticate_scope!
    self.resource =
    (params[:sfa_temp].present? ? resource_class.find_by_sf_auth_temp(params[:sfa_temp]) : nil)
  end

  def prepare_and_validate
    if resource.nil?
      flash[:error] = I18n.t('devise.two_factor_authentication.temp_token_error')
      redirect_to :root and return
    end
    @limit = resource.max_login_attempts
    if resource.max_login_attempts?
      sign_out(resource)
      render :max_login_attempts_reached and return
    end
  end
end
