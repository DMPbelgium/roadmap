# frozen_string_literal: true

# Purpose: attach domains to an org

module Ugent

  class OrgDomain < ApplicationRecord

    self.table_name = "ugent_org_domains"
    belongs_to :org
    validates :org, presence: true
    validates :name, length: { minimum: 1 }, uniqueness: true, hostname: true

  end

end
