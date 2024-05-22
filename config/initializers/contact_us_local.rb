# frozen_string_literal: true

# See base configuration file at config/initializers/contact_us.rb
# for more information
ContactUs.setup do |config|
  config.mailer_from = "dmponline@belnet.be"
  config.mailer_to = "servicedesk@belnet.be"
  config.require_name = true
  config.require_subject = true
  config.localize_routes = false
end
