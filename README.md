# How to setup project with Rails 5.1.x, React, Webpacker

## Create project
```
rails new . --webpack=react --database=postgresql -T
```

## Edit Gemfile
```ruby
gem 'dotenv-rails', '2.2.1'
gem 'bootstrap', '~> 4.0.0.alpha6'
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-facebook"
gem 'devise-bootstrapped', github: 'king601/devise-bootstrapped', branch: 'bootstrap4'
gem 'awesome_print'
```

then run:
```
bundle install
```

## Add Yarn packages
```
yarn add webpack webpack-merge js-yaml path-complete-extname webpack-manifest-plugin babel-loader@7.x coffee-loader coffee-script babel-core babel-preset-env babel-polyfill compression-webpack-plugin rails-erb-loader glob extract-text-webpack-plugin node-sass file-loader sass-loader css-loader style-loader postcss-loader autoprefixer postcss-smart-import precss resolve-url-loader babel-plugin-syntax-dynamic-import babel-plugin-transform-class-properties
```

and add more
```
yarn add redux react-redux redux-thunk redux-logger tether node-uuid jquery
```

## Config Devise
Install devise:
```
rails generate devise:install
```

Create model User:
```
rails g devise User
```

Create devise's views
```
rails generate devise:views:bootstrapped
```

Last, run:
```
rails db:migrate
```

## Generate model Identity
```
rails g model identity user:references provider:string access_token:string refresh_token:string uid:string name:string email:string nick_name:string image:string phone:string urls:string raw:json oauth_expires_at:datetime

rails db:migrate
```

## Connfig Omniauth
Edit devise config at `config/initializers/devise.rb`:
```ruby
config.omniauth :google_oauth2, ENV['GOOGLE_OAUTH2_APP_ID'], ENV['GOOGLE_OAUTH2_APP_SECRET'], { scope: "email" }
config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], { scope: "email" }
```

## Connect Devise with Omniauth
Add `:omniauthable, omniauth_providers: [:facebook, :google_oauth2]` to `app/models/user.rb`

Like this:
```ruby
devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
```

Create controller `app/controllers/user/omniauth_callbacks_controller.rb`
```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    generic_callback("facebook")
  end

  def google_oauth2
    generic_callback( "google_oauth2" )
  end

  def generic_callback(provider)
    @identity = User.from_omniauth(request.env["omniauth.auth"])

    @user = @identity || current_user
    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication
      set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
```

## Edit user model
Add to `app/models/user.rb` with below content:
```ruby
def self.new_with_session params, session
  super.tap do |user|
    if data = session["devise.facebook_data"] &&
      session["devise.facebook_data"]["extra"]["raw_info"]
      user.email = data["email"] if user.email.blank?
    end
  end
end

def self.from_omniauth(auth)
  where(email: auth.info.email).first_or_initialize.tap do |user|
    user.email = auth.info.email
    user.name = auth.info.name
    user.password = Devise.friendly_token[0,20]
    user.provider = auth.provider
    user.save!

    user.identities.where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |identity|
        identity.provider = auth.provider
        identity.uid = auth.uid
        identity.name = auth.info.name
        identity.email = auth.info.email
        identity.access_token = auth.credentials.token
        identity.oauth_expires_at = Time.at(auth.credentials.expires_at)
        identity.raw = auth.to_json
        identity.urls = (auth.info.urls || "").to_json
        identity.save!
    end
  end
end
```

## Update routes `config/routes`;
```ruby
devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
```

## Create .env
```
GOOGLE_OAUTH2_APP_ID=[your app id]
GOOGLE_OAUTH2_APP_SECRET=[your app secret]
FACEBOOK_APP_ID=[your app id]
FACEBOOK_APP_SECRET=[your app secret]
```

## How to run this project:
```
cd && git clone https://github.com/ntamvl/rails_5_1_react_webpacker_example.git
```

Edit database connection config at `config/database.yml` before run this command:

```
cd rails_5_1_react_webpacker_example
rails db:create db:migrate && yarn install
```

Add google, facebook app id, secret to file `.env`
Last run:
```
rails s
```

then visit page `http://localhost:3000/`

Enjoy :D

-------------------------------------------------------
**Refs:**
- http://willschenk.com/setting-up-devise-with-twitter-and-facebook-and-other-omniauth-schemes-without-email-addresses/
- https://www.crondose.com/2016/12/guide-integrating-omniauth-rails-5-facebook-login-feature/
- https://github.com/ntamvl/rails5_starter

