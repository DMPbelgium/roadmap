# frozen_string_literal: true

# local override

# disable new external apis (see config/initializers/external_apis/*.rb)
Rails.configuration.x.doi.active = false
Rails.configuration.x.open_aire.active = false
Rails.configuration.x.rdamsc.active = false
Rails.configuration.x.re3data.active = false
Rails.configuration.x.ror.active = false
Rails.configuration.x.spdx.active = false
