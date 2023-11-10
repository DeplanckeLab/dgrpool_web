class Study < ApplicationRecord

  belongs_to :status
  belongs_to :journal, :optional => true
  has_and_belongs_to_many :categories
  has_many :dgrp_line_studies
  has_many :phenotypes
end
