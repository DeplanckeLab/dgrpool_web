class Release < ApplicationRecord
  VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/

  has_and_belongs_to_many :downloads, -> { order(:id) }

  validates :name, presence: true, uniqueness: true, format: { with: VERSION_FORMAT, message: "must be a version like 0.0.1" }
  validates :url, presence: true
  validate :url_is_http

  after_create :create_download_directory
  after_update :move_download_directory, if: :saved_change_to_name?

  def self.by_version
    includes(:downloads).sort_by { |release| version_key(release.name) }.reverse
  end

  def self.version_key(name)
    name.to_s.split(".").map(&:to_i)
  end

  def self.downloads_root
    Pathname.new(APP_CONFIG[:data_dir]).join("downloads")
  end

  def download_directory
    self.class.downloads_root.join(name)
  end

  def file_path(download)
    filename = download.filename.to_s
    return nil unless filename.match?(Download::FILENAME_FORMAT)
    download_directory.join(filename)
  end

  def file_present?(download)
    path = file_path(download)
    !path.nil? && path.file?
  end

  def url_is_http
    uri = URI.parse(url.to_s)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "must be an http(s) URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "must be an http(s) URL")
  end

  def create_download_directory
    root = self.class.downloads_root
    stat = root.stat
    FileUtils.mkdir_p(download_directory)
    File.chmod(stat.mode & 0777, download_directory.to_s)
    File.chown(stat.uid, stat.gid, download_directory.to_s)
  end

  def move_download_directory
    previous = self.class.downloads_root.join(name_before_last_save)
    if previous.directory?
      FileUtils.mv(previous, download_directory)
    else
      create_download_directory
    end
  end
end
