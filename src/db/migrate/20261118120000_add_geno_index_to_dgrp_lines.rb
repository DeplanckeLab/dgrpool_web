class AddGenoIndexToDgrpLines < ActiveRecord::Migration[8.1]
  ## Position (0-based) of the line in snps.geno_string, i.e. in line 1 of the genoString file; nil = not genotyped.
  ## Set by 'rake load_dgrp_statuses'. Replaces the implicit mapping "lines with status 1/2 sorted by name".
  def change
    add_column :dgrp_lines, :geno_index, :integer
    add_index :dgrp_lines, :geno_index, unique: true
  end
end
