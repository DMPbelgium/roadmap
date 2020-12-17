# frozen_string_literal: true

# Purpose: previously a Plan could be removed, and we recorded that action in ugent_logs
# Now a plan is merely deactivated, and so remains in the database

module Ugent

  class Log < ApplicationRecord

    self.table_name = "ugent_logs"
    serialize :object, JSON
    serialize :whodunnit, JSON

  end

end
