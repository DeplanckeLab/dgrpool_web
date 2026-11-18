class DgrpLine < ApplicationRecord

  has_many :dgrp_line_studies
  belongs_to :dgrp_status, :optional => true

  validates :name, presence: true

  attribute :nber_studies, :integer, default: 0
  attribute :nber_phenotypes, :integer, default: 0

  ## Canonical line names stored in dgrp_lines.name:
  ##   DGRP2 lines -> DGRP_NNN  (3 digits, e.g. DGRP_021)
  ##   DGRP3 lines -> RP_NNNN   (4 digits, e.g. RP_0001, as in Bloomington "RP-0001")
  ## Accepted user inputs: DGRP-21, DGRP_021, line_21, RAL-21, 21 (any non-digit prefix
  ## for DGRP2, as before), and RP-1, RP_0001, RP1, rp-0001 for DGRP3.
  ## Returns nil when the value cannot be interpreted as a line name.
  RP_REGEX = /\A\s*RP[\s_-]?0*(\d{1,4})\s*\z/i

  def self.normalize_name(str)
    s = str.to_s.strip
    if m = s.match(RP_REGEX)
      "RP_%04d" % m[1].to_i
    elsif s.match(/\ARP/i)
      nil ## RP prefix but invalid number: never fall back to a DGRP_ name
    else
      nber = s.gsub(/\D/, '')
      (nber.size.between?(1, 3)) ? "DGRP_%03d" % nber.to_i : nil
    end
  end

  def self.rp_line?(name)
    name.to_s.start_with?('RP_')
  end

  ## Lines indexed by their position in snps.geno_string: result[i] is the line of character i (nil if unknown).
  ## geno_index is set by 'rake load_dgrp_statuses' from line 1 of the genoString file, so it does not depend on
  ## the statuses (which can be edited in the UI) nor on the alphabetical order of the names.
  def self.by_geno_index
    lines = []
    where.not(:geno_index => nil).each{|d| lines[d.geno_index] = d}
    lines
  end

  ## Parses line 1 of a genoString file ("#line_21,line_26,...,RP-0002,...") into canonical names (nil for invalid names)
  def self.parse_geno_header(header_line)
    header_line.to_s.chomp.sub(/\A#/, '').split(",").map{|v| normalize_name(v)}
  end

end
