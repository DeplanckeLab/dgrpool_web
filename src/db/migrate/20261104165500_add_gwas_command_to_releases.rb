class AddGwasCommandToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :gwas_command, :text
  end
end
