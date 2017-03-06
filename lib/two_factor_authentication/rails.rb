module TwoFactorAuthentication
  class Engine < ::Rails::Engine
    ActiveSupport.on_load(:action_controller) do
      include TwoFactorAuthentication::Controllers::Helpers
    end
    ActiveSupport::Reloader.to_prepare do
      TwoFactorAuthentication::Patches.apply
    end
  end
end
