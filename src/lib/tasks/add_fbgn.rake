desc '####################### add_fbgn'
task add_fbgn: :environment do
  puts 'Executing...'

  
  annot_file = Pathname.new(APP_CONFIG[:data_dir]) + 'dgrp.fb557.annot.txt.gz'

  puts "Load snps..."
#  h_snps = {}
#  Snp.all.map{|s| h_snps[s.identifier] = s.id}
  
  h_sex = {
    'F' => 'female',
    'M' => 'male',
    'NA' => 'na'
  }

  puts "Load genes"
  h_genes = {}
  h_fbgn = {}
  Gene.all.map{|g| h_genes[g.name] = g; h_fbgn[g.name] = g.identifier}

  puts "Parse files..."
  
  File.open(annot_file, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
   
      gz.each_line do |l|
        t = l.split("\t")
        t[2].split(",").each do |e|
 #         puts e
          #                                  SiteClass[FBgn0035398|Cht7|INTRON|0;FBgn0052286|tRNA:CR32286|DOWNSTREAM|375]
            if m = e.match(/^(\w+)\[(.+?)\]$/)
              if m[1] == 'SiteClass'
                m2 = m[2].split("|")
                #  if h_genes[m2[1]]
                h_fbgn[m2[1]] = m2[0]
 #               puts m2.to_json
#                exit
              end
            end
        end
      end
    end

  end
    
  #puts h_fbgn.to_json
  
  ## update DB
  puts "Update DB..."
  h_fbgn.each_key do |gene_name|
#    puts h_genes[gene_name].to_json
    if h_genes[gene_name]
      h_genes[gene_name].update(:identifier => h_fbgn[gene_name], :in_vcf => true)
      #    puts h_genes[gene_name].to_json
      #    exit
    else
      new_gene = Gene.new(:name => gene_name, :identifier => h_fbgn[gene_name], :in_vcf => true)
      new_gene.save
    end
  end
  
end

