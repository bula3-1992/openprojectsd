class AddProjectIdToContracts < ActiveRecord::Migration[5.2]
  def change
    add_column :contracts, :project_id, :integer
  end
end
