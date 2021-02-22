# frozen_string_literal: true

# Purpose: attach domains to an org

=begin create table in mysql

CREATE TABLE `ugent_org_domains` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `org_id` int NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_organisation_domains_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

=end

module Ugent

  class OrgDomain < ApplicationRecord

    self.table_name = "ugent_org_domains"
    belongs_to :org
    validates :org, presence: true
    validates :name,
      presence: true,
      length: { minimum: 1 },
      uniqueness: true,
      hostname: true

  end

end
