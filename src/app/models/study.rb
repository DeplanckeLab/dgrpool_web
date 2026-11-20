class Study < ApplicationRecord

  belongs_to :status
  belongs_to :journal, :optional => true
  has_and_belongs_to_many :categories
  has_many :dgrp_line_studies
  has_many :phenotypes

  # Per-study phenotype data, stored as JSON text: ~65 MB over all studies, which made every `Study.all` take
  # ~0.5 s. Pages that only display references or lists use `Study.without_pheno_data`; reading one of these
  # columns on such a record raises ActiveModel::MissingAttributeError.
  PHENO_DATA_COLUMNS = %w[pheno_json pheno_json_old pheno_sum_json pheno_mean_json pheno_median_json].freeze

  scope :without_pheno_data, -> { select(*(column_names - PHENO_DATA_COLUMNS).map { |c| arel_table[c] }) }
end
