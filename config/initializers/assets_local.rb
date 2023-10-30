# frozen_string_literal: true

# overrides for/additions to config/initializers/assets.rb

Rails.application.config.assets.precompile += ["rails_admin/rails_admin.css", "rails_admin/rails_admin.js"]
