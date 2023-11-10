class DgrpLine < ApplicationRecord

  has_many :dgrp_line_studies
  belongs_to :dgrp_status, :optional => true

end
