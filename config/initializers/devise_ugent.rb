# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Devise.setup do |config|
  config.mailer_sender = "info@dmponline.be"
  OmniAuth.config.full_host = ENV["BASE_URL"]
  config.omniauth(
    :orcid,
    ENV["ORCID_CLIENT_ID"],
    ENV["ORCID_CLIENT_SECRET"], {
      member: false,
      sandbox: false
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