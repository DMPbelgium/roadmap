# frozen_string_literal: true

# See base configuration file at config/initializers/contact_us.rb
# for more information
ContactUs.setup do |config|
  config.mailer_from = "info@dmponline.be"
  config.mailer_to = "info@dmponline.be"
  config.require_name = true
  config.require_subject = true
  config.localize_routes = false
end
