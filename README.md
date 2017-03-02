# Two factor authentication for Devise
This fork is in active development. The new features, seems to be stable but still,
These are not fully tested or used in production yet. Use with your own risk.
## Features

* Support for 2 types of OTP codes
 1. Codes delivered directly to the user
 2. TOTP (Google Authenticator) codes based on a shared secret (HMAC)
* Configurable OTP code digit length
* Configurable max login attempts
* Customizable logic to determine if a user needs two factor authentication
* Configurable period where users won't be asked for 2FA again
* Option to encrypt the TOTP secret in the database, with iv and salt

## Configuration

### Initial Setup

In a Rails environment, require the gem in your Gemfile:

    gem 'two_factor_authentication'

Once that's done, run:

    bundle install

And run below to add Devise config values in `config/initializers/devise.rb`:

    bundle exec rails g two_factor_authentication:install

You need to set `OTP_SECRET_ENCRYPTION_KEY` environment key to encrypt google
authentication secretes. For development environment, you can use a gem like,
[dotenv](https://github.com/bkeepers/dotenv) or [figaro](https://github.com/laserlemon/figaro).

The `OTP_SECRET_ENCRYPTION_KEY` must be a random key that is not stored in the
DB, and is not checked in to your repo. It is recommended to store it in an
environment variable, and you can generate it with `bundle exec rake secret`.

Note that Ruby 2.1 or greater is required.

### Installation

#### Automatic initial setup

To set up the model and database migration file automatically, run the
following command:

    bundle exec rails g two_factor_authentication MODEL

Where MODEL is your model name (e.g. User or Admin). This generator will add
`:two_factor_authenticatable` to your model's Devise options and create a
migration in `db/migrate/`, which will add the following columns to your table:

- `:second_factor_attempts_count`
- `:encrypted_otp_secret_key`
- `:encrypted_otp_secret_key_iv`
- `:encrypted_otp_secret_key_salt`
- `:direct_otp`
- `:direct_otp_sent_at`
- `:totp_timestamp`

#### Manual initial setup

If you prefer to set up the model and migration manually, add the
`:two_factor_authentication` option to your existing devise options, such as:

```ruby
devise :database_authenticatable, :registerable, :recoverable, :rememberable,
       :trackable, :validatable, :two_factor_authenticatable
```

Then create your migration file using the Rails generator, such as:

```
rails g migration AddTwoFactorFieldsToUsers second_factor_attempts_count:integer encrypted_otp_secret_key:string:index encrypted_otp_secret_key_iv:string encrypted_otp_secret_key_salt:string direct_otp:string direct_otp_sent_at:datetime totp_timestamp:timestamp
```

Open your migration file (it will be in the `db/migrate` directory and will be
named something like `20151230163930_add_two_factor_fields_to_users.rb`), and
add `unique: true` to the `add_index` line so that it looks like this:

```ruby
add_index :users, :encrypted_otp_secret_key, unique: true
```
Save the file.

#### Complete the setup

Run the migration with:

    bundle exec rake db:migrate

Add the following line to your model to fully enable two-factor auth:

    has_one_time_password(encrypted: true)

Override the method in your model in order to send direct OTP codes. This is
automatically called when a user logs in unless they have TOTP enabled (see
below):

```ruby
def send_two_factor_authentication_code(code)
  # Send code via SMS, etc.
end
```

### Customisation and Usage

By default, second factor authentication is required for each user. You can
change that by overriding the following method in your model:

```ruby
def need_two_factor_authentication?(request)
  request.ip != '127.0.0.1'
end
```

In the example above, two factor authentication will not be required for local
users.

This gem is compatible with [Google Authenticator](https://support.google.com/accounts/answer/1066447?hl=en).
And by default this feature is disabled and default way of second factor validation is direct OTP.
To enable this for a model override the following method to return true:

```ruby
def gauth_enabled?
  true
  # or you can create a attribute(DB column) like 'gauth_enabled' for
  # this model so that each individual users setting can be controlled
  # instaed of whole model.
end
```
Please note that, this only enables this functionality. For complete setup, follow below steps:
**STEP 1**:
User signs up.
**STEP 2**:
User visits the page `/users/displayqr`.
(This url will be in format of `/resource/displayqr`.For example, for activeadmin default model
`AdminUser`, it will be `/admin_users/displayqr`)
**STEP 3**:
In the above page, there will be a QR code shown. User needs to scan that in Google Authenticator
App. And then check of checkbox for activation. Fill the text box with the code, currently
shown in the Google Authenticator app and submit.
Now user is activated for Google Authentication.

If the user is not auto logged in after signup or user is created by Admin, then users needs to
login the very first time, using **Direct Otp** and the follow step 2 and 3.
Once this is done, they
may retrieve a one-time password directly from the Google Authenticator app.

#### Overriding the view

The default view that shows the form can be overridden by adding a
file named `show.html.erb` (or `show.html.haml` if you prefer HAML)
inside `app/views/devise/two_factor_authentication/` and customizing it.
Below is an example using ERB:


```html
<h2>Hi, you received a code by email, please enter it below, thanks!</h2>

<%= form_tag([resource_name, :two_factor_authentication], :method => :put) do %>
  <%= text_field_tag :code %>
  <%= submit_tag "Log in!" %>
<% end %>

<%= link_to "Sign out", destroy_user_session_path, :method => :delete %>
```

#### Upgrading from version 1.X to 2.X

The following database fields are new in version 2.

- `direct_otp`
- `direct_otp_sent_at`
- `totp_timestamp`

To add them, generate a migration such as:

    $ rails g migration AddTwoFactorFieldsToUsers direct_otp:string direct_otp_sent_at:datetime totp_timestamp:timestamp

The `otp_secret_key` is not only required for users who use Google Authentictor,
so unless it has been shared with the user it should be set to `nil`.  The
following pseudo-code is an example of how this might be done:

```ruby
User.find_each do |user| do
  if !uses_authentictor_app(user)
    user.otp_secret_key = nil
  end
end
```

#### Adding the TOTP encryption option to an existing app

If you've already been using this gem, and want to start encrypting the OTP
secret key in the database (recommended), you'll need to perform the following
steps:

1. Generate a migration to add the necessary columns to your model's table:

   ```
   rails g migration AddEncryptionFieldsToUsers encrypted_otp_secret_key:string:index encrypted_otp_secret_key_iv:string encrypted_otp_secret_key_salt:string
   ```

   Open your migration file (it will be in the `db/migrate` directory and will be
   named something like `20151230163930_add_encryption_fields_to_users.rb`), and
   add `unique: true` to the `add_index` line so that it looks like this:

   ```ruby
   add_index :users, :encrypted_otp_secret_key, unique: true
   ```
   Save the file.

2. Run the migration: `bundle exec rake db:migrate`

2. Update the gem: `bundle update two_factor_authentication`

3. Add `encrypted: true` to `has_one_time_password` in your model.
   For example: `has_one_time_password(encrypted: true)`

4. Generate a migration to populate the new encryption fields:
   ```
   rails g migration PopulateEncryptedOtpFields
   ```

   Open the generated file, and replace its contents with the following:
   ```ruby
   class PopulateEncryptedOtpFields < ActiveRecord::Migration
      def up
        User.reset_column_information

        User.find_each do |user|
          user.otp_secret_key = user.read_attribute('otp_secret_key')
          user.save!
        end
      end

      def down
        User.reset_column_information

        User.find_each do |user|
          user.otp_secret_key = ROTP::Base32.random_base32
          user.save!
        end
      end
    end
  ```

5. Generate a migration to remove the `:otp_secret_key` column:
   ```
   rails g migration RemoveOtpSecretKeyFromUsers otp_secret_key:string
   ```

6. Run the migrations: `bundle exec rake db:migrate`

If, for some reason, you want to switch back to the old non-encrypted version,
use these steps:

1. Remove `(encrypted: true)` from `has_one_time_password`

2. Roll back the last 3 migrations (assuming you haven't added any new ones
after them):
   ```
   bundle exec rake db:rollback STEP=3
   ```

### Example App

[TwoFactorAuthenticationExample](https://github.com/Houdini/TwoFactorAuthenticationExample)
