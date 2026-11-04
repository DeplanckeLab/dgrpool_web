class Download < ApplicationRecord
  FILENAME_FORMAT = /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/

  has_and_belongs_to_many :releases

  validates :filename, presence: true, uniqueness: true, format: { with: FILENAME_FORMAT }
  validates :description, presence: true
end
