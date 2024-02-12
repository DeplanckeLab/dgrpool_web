class DgrpLineStudy < ApplicationRecord

  belongs_to :study
  belongs_to :dgrp_line
  has_and_belongs_to_many :phenotypes
#  has_and_belongs_to_many :phenotype_keywords

end
