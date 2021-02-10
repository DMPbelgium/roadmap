# frozen_string_literal: true

# Purpose: token based authentication for organisation plan exports

=begin create table in mysql

CREATE TABLE `ugent_rest_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `org_id` int NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8

=end

module Ugent

  class RestUser < ApplicationRecord

    self.table_name = "ugent_rest_users"

    belongs_to :org

    validates :org, presence: true
    validates :name, length: { minimum: 1 }, uniqueness: true
    validates :code,
      length: { minimum: 1 },
      uniqueness: true,
      format: { with: /\A[a-zA-Z0-9]+\z/ }
    validates :token,
      length: { minimum: 10 }

    before_validation do |record|

      if record.new_record?

        record.token = RestUser.generate_token()

      end

    end

    def self.generate_token

      SecureRandom.uuid()

    end

    def self.verify_and_load(org,code,token)

      self.where(code: code, token: token, org_id: org.id).first

    end

  end

end
