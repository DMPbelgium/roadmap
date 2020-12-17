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
      uid_field: ENV["SHIBBOLETH_UID_FIELD"],
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
