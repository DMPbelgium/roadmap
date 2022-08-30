class AddApiClientIdToPlans < ActiveRecord::Migration[4.2]
  #def change
  #  add_column :plans, :api_client_id, :integer, index: true
  #end
  def up
    unless column_exists? :plans, :api_client
      add_column :plans, :api_client_id, :integer, index: true
    end
  end
  def down
    if index_exists? :plans, :api_client_id
      remove_index :plans, :api_client_id
    end
    if column_exists? :plans, :api_client
      remove_column :plans, :api_client_id, :integer
    end
  end
end
