module TwoFactorAuthenticatable
  module Generators # :nodoc:
    # Install Generator
    class InstallGenerator < Rails::Generators::Base
      namespace "two_factor_authentication:install"
      source_root File.expand_path("../../templates", __FILE__)

      desc "Install the two factor authentication extension"

      def add_configs
        inject_into_file "config/initializers/devise.rb",
        "\n  # ==> two factor authentication Extension\n  # Configure extension for devise\n  # \n" +
        "  # Maximum second factor attempts count.\n" +
        "  config.max_login_attempts = 3\n" +
        "  # Allowed TOTP time drift between client and server.\n" +
        "  config.allowed_otp_drift_seconds = 30\n" +
        "  # TOTP code length.\n" +
        "  config.otp_length = 6\n" +
        "  # Time before direct OTP becomes invalid.\n" +
        "  config.direct_otp_valid_for = 5.minutes\n" +
        "  # Direct OTP code length.\n" +
        "  config.direct_otp_length = 6\n" +
        "  # Time before browser has to perform 2fA again. Default is 0.\n" +
        "  # config.remember_otp_session_for_seconds = 30.days\n" +
        "  # Set key for encryption of google OTP secret\n" +
        "  config.otp_secret_encryption_key = ENV['OTP_SECRET_ENCRYPTION_KEY'] \n" +
        "  # Field or method name used to set value for 2fA remember cookie.\n" +
        "  config.second_factor_resource_id = 'id'\n" +
        "\n", :before => /end[ |\n|]+\Z/
      end
    end
  end
end