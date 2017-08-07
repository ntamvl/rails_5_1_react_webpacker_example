class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
  has_many :identities

  def self.new_with_session params, session
    super.tap do |user|
      if data = session["devise.facebook_data"] &&
          session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  # def self.from_omniauth auth
  #   ap auth
  #   where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
  #     user.email = auth.info.email
  #     user.password = Devise.friendly_token[0,20]
  #     user.name = auth.info.name
  #     user.image = auth.info.image
  #   end
  # end

  def self.from_omniauth(auth)
    ap auth
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

end
