json.extract! release, :id, :name, :description, :url, :gwas_command, :release_date, :created_at, :updated_at
json.url release_url(release, format: :json)
json.downloads release.downloads do |download|
  json.extract! download, :id, :filename, :description
  json.available release.file_present?(download)
  if release.file_present?(download)
    json.file_url file_release_url(release, name: download.filename)
  end
end
