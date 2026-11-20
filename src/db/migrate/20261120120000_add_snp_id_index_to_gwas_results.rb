class AddSnpIdIndexToGwasResults < ActiveRecord::Migration[8.1]
  ## DGRP3: gwas_results grows to ~9.5M rows. PheWAS, variant search and gene pages query it by snp_id, which was
  ## not indexed (one full table scan per page). Faster to create after 'rake load_phewas' than before.
  def change
    add_index :gwas_results, :snp_id
  end
end
