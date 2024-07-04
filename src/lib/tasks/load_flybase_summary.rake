desc '####################### load flybase summary'
task load_flybase_summary: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  h_summary = {}
  h_genes = {}
  Gene.all.map{|g| h_genes[g.identifier] = g; h_genes[g.name] = g; h_summary[g.identifier] = {}}
  
  summary_file_path = data_dir + "flybase" + "best_gene_summary_fb_2024_02.tsv.gz"



#FBgn_ID        Gene_Symbol     Summary_Source  Summary
#FBgn0031081     Nep3    UniProtKB       Metalloendoprotease which is required in the dorsal paired medial neurons for the proper formation of long-term (LTM) and middle-term memories (MTM). Also required in the mushroom body neurons where it functions redundantly with neprilysins Nep2 and Nep4 in normal LTM formation. (UniProtKB:Q9W5Y0)

  header = [:gene_identifier, :gene_name, :summary_source, :summary]
  
  puts "parse#{summary_file_path}..." 
  File.open(summary_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here
        if !line.match(/^\#/)
          t = line.chomp.split("\t")
          h = {}
          header.each_index do |i|
            h[header[i]] = t[i]
          end

          if h_genes[h[:gene_identifier]]
            h_summary[h[:gene_identifier]][h[:summary_source]] = h[:summary]
       #     puts h[:gene_identifier]
       #     puts h_summary[h[:gene_identifier]].to_json
       #     exit
          end
        end
      end
    end
  end

  puts h_summary.keys.size
 
  ## load in DB
  ActiveRecord::Base.transaction do
    h_summary.each_key do |identifier|
      if h_genes[identifier]
        h_genes[identifier].update(:summary_json => h_summary[identifier].to_json)
      end
    end
  end
  
end
