class Devise::DisplayqrController < DeviseController
  prepend_before_filter :authenticate_scope!, :only => [:show, :update]

  include Devise::Controllers::Helpers

  # GET /resource/displayqr
  def show
    if resource.nil? || !resource.gauth_enabled?
      sign_in resource_class.new, resource
      redirect_to stored_location_for(scope) || :root
    else
      @tmpid = resource.generate_totp_secret
      url = resource.provisioning_uri(nil, otp_secret_key: @tmpid)
      qrcode = RQRCode::QRCode.new(url, level: :m, mode: :byte_8bit)
      png = qrcode.as_png(fill: 'white', color: 'black', border_modules: 1, module_px_size: 4)
      @qr_url = "data:image/png;base64,#{Base64.encode64(png.to_s).strip}"
      render :show
    end
  end

  def update

    if params['gauth_enabled']
      if !resource.confirm_totp_secret(params['tmpid'], params['otp_secret_key'])
        flash[:error] = I18n.t('devise.two_factor_authentication.qr_invalid_token')
        redirect_to action: 'show' and return
      end
      resource.save
      flash[:notice] = I18n.t('devise.two_factor_authentication.gauth_enabled')
      sign_in scope, resource, :bypass => true
    else
      resource.otp_secret_key = nil
      resource.save
      flash[:notice] = I18n.t('devise.two_factor_authentication.gauth_disabled')
    end
    redirect_to stored_location_for(scope) || :root
  end

  private
  def scope
    resource_name.to_sym
  end

  def authenticate_scope!
    send(:"authenticate_#{resource_name}!")
    self.resource = send("current_#{resource_name}")
  end

end