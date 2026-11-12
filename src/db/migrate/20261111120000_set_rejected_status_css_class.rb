class SetRejectedStatusCssClass < ActiveRecord::Migration[7.0]
  ## 'error' is not a Bootstrap class (bg-error renders white); use 'danger' (red)
  def up
    execute "UPDATE statuses SET css_class = 'danger' WHERE name = 'rejected'"
  end

  def down
    execute "UPDATE statuses SET css_class = 'error' WHERE name = 'rejected'"
  end
end
