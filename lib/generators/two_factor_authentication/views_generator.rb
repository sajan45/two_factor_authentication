require 'generators/devise/views_generator'

module TwoFactorAuthentication
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc 'Copies all Two Factor Authentication views to your application.'

      argument :scope, :required => false, :default => nil,
                       :desc => "Scope for views, if using multiple scopes"

      include ::Devise::Generators::ViewPathTemplates
      source_root File.expand_path("../../../../app/views/devise", __FILE__)
      def copy_views
        # if plural_scope
        #   modified_target_path = "app/views/#{plural_scope}/devise"
        # else
        #   modified_target_path = "app/views/devise"
        # end
        view_directory :displayqr#, (modified_target_path + "/displayqr")
        view_directory :two_factor_authentication#, (modified_target_path + "/two_factor_authentication")
      end
    end
  end
end