class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #       :recoverable, :rememberable, :validatable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_google(auth)
    if ENV['GOOGLE_DOMAIN'].present?
      return unless auth.info.email.end_with?(ENV['GOOGLE_DOMAIN'])
    end

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.full_name = auth.info.name
      user.avatar_url = auth.info.image
    end
  end
end
