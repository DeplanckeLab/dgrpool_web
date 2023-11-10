desc '####################### load flybase reference'
task load_flybase_reference: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  file = data_dir + 'flybase_references.tsv.gz'
  url = "http://ftp.flybase.net/releases/FB2022_06/precomputed_files/references/fbrf_pmid_pmcid_doi_fb_2022_06.tsv.gz"
  `wget -O #{file} #{url}`
  `gunzip #{file}`

  file = data_dir + "flybase_references.tsv"
  File.open(file, 'r') do |f|
    while (l = f.gets) do
      t = l.chomp.split("\t")
      if t.size > 3
        puts t[3]
        study = Study.where(:doi => t[3]).first
        if study
          study.update(:flybase_ref => t[0])
        end
      end
    end
  end
  
  
end
