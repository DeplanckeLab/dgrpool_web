require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

desc '####################### export'
task export: :environment do
  puts 'Executing...'

  def esc e
    return (e) ? e.gsub(/\s+/, ' ') : e
  end

  h_studies = {}
  Study.all.map{|s| h_studies[s.id] = s}
  h_statuses = {}
  Status.all.map{|s| h_statuses[s.id] = s}
  
  download_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'downloads'
  Dir.mkdir download_dir if !File.exist? download_dir

  filename = download_dir + 'studies.tsv'
  File.open(filename, 'w') do |f|
    f.write(["study_id", "authors", "title", "journal", "issue", "volume", "year", "doi", "nber_phenotypes", "comment", "description", "categories", "status", "flybase_ref"].join("\t") + "\n")
    Study.all.sort.each do |s|
      f.write([s.id, JSON.parse(s.authors_json).map{|e| [e['fname'], e['lname']].join(",") }, s.title, (j = s.journal) ? j.name : '', s.issue, s.volume, s.year, s.doi, s.phenotypes.select{|e| e.obsolete == false}.size, esc(s.comment), esc(s.description), s.categories.map{|e| e.name}.join(","), s.status.name, s.flybase_ref].join("\t") + "\n")
    end
  end

  filename = download_dir + 'phenotypes.tsv'
  File.open(filename, 'w') do |f|
    f.write(["phenotype_id", "phenotype_name", "study_id", "study_name", "study_status", "dataset_type", "raw_dataset_id", "nber_dgrp_lines", "nber_sex_female", "nber_sex_male", "nber_sex_na", "is_numeric", "is_continuous", "summary_type", "unit", "description"].join("\t") + "\n")
    Phenotype.where(:obsolete => false).all.sort.each do |p|
      f.write([p.id, p.name, p.study_id, display_reference_short(h_studies[p.study_id]), h_statuses[h_studies[p.study_id].status_id].name, ((p.dataset_id == nil) ? 'summary' : 'raw'), p.dataset_id, p.nber_dgrp_lines, p.nber_sex_female, p.nber_sex_male, p.nber_sex_na, p.is_numeric, p.is_continuous, ((p.summary_type) ? p.summary_type.name : 'NA'), ((p.unit) ? p.unit.label : 'NA'), esc(p.description)].join("\t") + "\n")
    end
  end

  filename = download_dir + 'dgrp_lines.tsv'
  File.open(filename, 'w') do |f|
    f.write(["dgrp", "nber_studies", "nber_phenotypes", "dgrp_status", "fbsn", "bloomington_id"].join("\t") + "\n")
    DgrpLine.all.sort{|a, b| a.name.gsub(/[^\d]/, '').to_i <=> b.name.gsub(/[^\d]/, '').to_i}.each do |d|
      f.write([
                d.name, d.nber_studies, d.nber_phenotypes, d.dgrp_status.name, d.fbsn, d.bloomington_id
              ].join("\t") + "\n")
    end
  end
  
  
  
end

