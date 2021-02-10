# frozen_string_literal: true

# Purpose: attaches shibboleth login routes (i.e. identity servers) to an organisation
#          this is kept as backup, and should be replaced by Identifier

=begin create table in mysql

CREATE TABLE `ugent_wayfless_entities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `url` text NOT NULL,
  `org_id` int NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_wayfless_entities_on_name` (`name`),
  UNIQUE KEY `index_wayfless_entities_on_url` (`url`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8

=end

module Ugent

  class WayflessEntity < ApplicationRecord

    self.table_name = "ugent_wayfless_entities"
    belongs_to :org
    validates :org, presence: true
    validates :name, length: { minimum: 1 }, uniqueness: true
    validates_format_of :url, with: URI.regexp(%w(http https)), allow_blank: false
    validates :url, uniqueness: true

  end

end
