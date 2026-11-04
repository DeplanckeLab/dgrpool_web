class CreateReleasesAndDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :downloads do |t|
      t.text :filename, null: false
      t.text :description, null: false
      t.timestamps
    end
    add_index :downloads, :filename, unique: true

    create_table :releases do |t|
      t.text :name, null: false
      t.text :description
      t.text :url, null: false
      t.timestamps
    end
    add_index :releases, :name, unique: true

    create_table :downloads_releases, id: false do |t|
      t.references :download, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true
    end
    add_index :downloads_releases, [:download_id, :release_id], unique: true, name: "index_downloads_releases_on_download_and_release"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO downloads (filename, description, created_at, updated_at) VALUES
            ('dgrp_lines.tsv', 'DGRP lines (TSV)', NOW(), NOW()),
            ('phenotypes.tsv', 'Phenotypes (TSV)', NOW(), NOW()),
            ('studies.tsv', 'Studies (TSV)', NOW(), NOW()),
            ('all_phenotype_mean_data.tsv', 'All phenotype mean (numerical) data by sex (TSV)', NOW(), NOW())
        SQL
      end
    end
  end
end
