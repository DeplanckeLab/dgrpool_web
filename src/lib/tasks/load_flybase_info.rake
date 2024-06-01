desc '####################### load flybase info'
task load_flybase_info: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  h_genes = {}
  Gene.all.map{|g| h_genes[g.identifier] = g; h_genes[g.name] = g;}
  
  summary_file_path = data_dir + "flybase" + "fb_synonym_fb_2024_02.tsv.gz"

  ##primary_FBid  organism_abbreviation   current_symbol  current_fullname        fullname_synonym(s)     symbol_synonym(s)
  #FBal0000001     Dmel    alpha-Spec[1]                   

  header = [:gene_identifier, :organism, :name, :full_name, :fullname_synonyms, :name_synonyms]
  
  puts "parse#{summary_file_path}..." 
  File.open(summary_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here
        if !line.match(/^\#/) and line.chomp.strip != ''
          t = line.chomp.split("\t")
          h = {}
          header.each_index do |i|
            h[header[i]] = t[i] || ''
          end
          
          if h_genes[h[:gene_identifier]]
#            puts line
            h_upd = {
              :full_name => h[:full_name],
              :synonyms => (h[:fullname_synonyms].split("|") + h[:name_synonyms].split("|")).uniq.sort{|a, b| b.size <=> a.size}.join("|")
            }
            
            h_genes[h[:gene_identifier]].update(h_upd)
          end
        end
      end
    end
  end

end
