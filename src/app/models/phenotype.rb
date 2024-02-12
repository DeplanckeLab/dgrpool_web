class Phenotype < ApplicationRecord

  belongs_to :study
  belongs_to :unit, :optional => true
  belongs_to :summary_type, :optional => true
  has_many :gwas_results
  has_and_belongs_to_many :dgrp_line_studies

  validates :name, length: { maximum: 20 }
  validates :name, format: { with: /\A[a-zA-Z_0-9]+\z/, message: "only allows letters, numbers and _ characters" }

  
  searchable do
    text :name
    text :description
    string :name_order do
      name
    end
    boolean :integrated_study do
      (study.status_id == 4) ? true : false 
    end
    text :study_authors do
      study.authors
    end
   integer :dgrp_line_ids, :multiple => true do
      dgrp_line_studies.map{|e| e.dgrp_line_id}.uniq
    end
    boolean :has_dgrp_line_studies do
      (dgrp_line_studies.size > 0) ? true : false
    end
    boolean :is_numeric
    boolean :obsolete
  end
   
end
