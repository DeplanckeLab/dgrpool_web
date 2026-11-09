class DgrpLine < ApplicationRecord

  has_many :dgrp_line_studies
  belongs_to :dgrp_status, :optional => true

  validates :name, presence: true

  attribute :nber_studies, :integer, default: 0
  attribute :nber_phenotypes, :integer, default: 0

end
