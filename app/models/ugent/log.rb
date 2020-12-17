# frozen_string_literal: true

module Ugent

  class Log < ApplicationRecord

    self.table_name = "ugent_logs"
    serialize :object, JSON
    serialize :whodunnit, JSON

  end

end
