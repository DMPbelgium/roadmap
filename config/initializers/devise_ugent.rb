# frozen_string_literal: true

ENV["BASE_URL"] ||= "http://localhost:3000"

# rubocop:disable Metrics/BlockLength
Devise.setup do |config|
  config.mailer_sender = "info@dmponline.be"
  OmniAuth.config.full_host = ENV["BASE_URL"]
  config.omniauth(
    :orcid,
    ENV["ORCID_CLIENT_ID"],
    ENV["ORCID_CLIENT_SECRET"], {
      member: true,
      sandbox: false,
      authorize_params: {
        # default scope for member api is too broad ("/read-limited /activities/update /person/update")
        scope: "/read-limited"
      }
    }
  )
  config.omniauth(
    :shibboleth, {
      # use 'header' when rails runs behind a reverse proxy, use env when inside passenger
      # in the first case, add apache option "ShibUseHeaders On"
      request_type: :header,
      uid_field: :mail,
      fields: [],
      extra_fields: %i[
        persistent-id
        eppn
        affiliation
        entitlement
        unscoped-affiliation
        targeted-id
        mail
        sn
        givenname
        department
        faculty
      ]
    }
  )
end
# rubocop:enable Metrics/BlockLength

# fix for api_base_url (see https://github.com/datacite/omniauth-orcid/pull/15/files)
require "omniauth/strategies/orcid"
module OmniAuth
  module Strategies
    class ORCID

      def api_base_url
        site + "/v#{API_VERSION}"
      end

      # warning: setting env OAUTH_DEBUG=true gives StackLocked
      # cf. https://github.com/oauth-xx/oauth2/issues/189
      def request_info
        @request_info ||= access_token.get( "#{api_base_url}/#{uid}/person", headers: { accept: 'application/json' } ).parsed || {}
      end

    end
  end
end
