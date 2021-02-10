# frozen_string_literal: true

# Purpose: previously a Plan could be removed, and we recorded that action in ugent_logs
# Now a plan is merely deactivated, and so remains in the database

=begin create database in mysql

CREATE TABLE `ugent_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `item_id` int DEFAULT NULL,
  `item_type` varchar(255) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `whodunnit` text,
  `whodunnit_id` int DEFAULT NULL,
  `object` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ugent_logs_on_item_type` (`item_type`),
  KEY `index_ugent_logs_on_whodunnit_id` (`whodunnit_id`),
  KEY `index_ugent_logs_on_event` (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

=end

module Ugent

  class Log < ApplicationRecord

    self.table_name = "ugent_logs"
    serialize :object, JSON
    serialize :whodunnit, JSON

  end

end
