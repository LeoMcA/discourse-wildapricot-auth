# name: wildapricot-auth
# about: Discourse plugin which adds Wild Apricot authentication
# version: 0.0.1
# authors: Leo McArdle

require 'auth/oauth2_authenticator'
require 'omniauth-oauth2'
require 'base64'

class WildApricotAuthenticator < ::Auth::OAuth2Authenticator
  def register_middleware(omniauth)
    omniauth.provider :wildapricot,
      SiteSetting.wildapricot_client_id,
      SiteSetting.wildapricot_client_secret
  end
end

after_initialize do
  class ::OmniAuth::Strategies::Wildapricot
    option :name, 'wildapricot'

    option :client_options, {
      :site => SiteSetting.wildapricot_server,
      :authorize_url => '/sys/login/OAuthLogin',
      :token_url => 'https://oauth.wildapricot.org/auth/token'
    }

    option :authorize_params, {
      :response_type => 'authorization_code',
      :scope => 'contacts_me',
      :claimed_account_id => SiteSetting.wildapricot_account_id
    }

    authorization_header = Base64.strict_encode64("#{SiteSetting.wildapricot_client_id}:#{SiteSetting.wildapricot_client_secret}")

    option :token_params, {
      :scope => 'contacts_me',
      :headers => {
        'Authorization' => "Basic #{authorization_header}"
      }
    }

    uid { raw_info['Id'].to_s }

    info do
      {
        :email => raw_info['Email'],
        :name => "#{raw_info['FirstName']} #{raw_info['LastName']}"
      }
    end

    extra do
      {
        :raw_info => raw_info
      }
    end

    def raw_info
      @raw_info ||= access_token.get("https://api.wildapricot.org/v2/Accounts/#{SiteSetting.wildapricot_account_id}/Contacts/Me").parsed
    end
  end
end

class OmniAuth::Strategies::Wildapricot < OmniAuth::Strategies::OAuth2
end

auth_provider :title => 'with Wild Apricot',
  :message => 'Authentication with Wild Apricot (make sure pop up blockers are not enabled)',
  :frame_width => 660,
  :frame_height => 650,
  :authenticator => WildApricotAuthenticator.new('wildapricot', trusted: true)

register_css <<CSS

.btn-social.wildapricot {
  background: #006f3b;
}

CSS
