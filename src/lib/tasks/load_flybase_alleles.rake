desc '####################### load flybase_alleles'
task load_flybase_alleles: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  h_alleles = {}

  h_genes = {}
  Gene.all.map{|g| h_genes[g.identifier] = g; h_genes[g.name] = g}
  
  gene_allele_file_path = data_dir + "flybase" + "fbal_to_fbgn_fb_2024_02.tsv.gz"
  #       AlleleID        AlleleSymbol    GeneID  GeneSymbol
  #FBal0137236     gukh[142]       FBgn0026239     gukh
  #FBal0137618     Xrp1[142]       FBgn0261113     Xrp1

  header = [:identifier, :allele_symbol, :gene_id, :gene_name]
  
  puts "parse #{gene_allele_file_path}..." 
  File.open(gene_allele_file_path, 'rb') do |file|
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

          ## add gene if doesn't exist
          gene = h_genes[h[:gene_id]] || h_genes[h[:gene_name]]
          if !gene
            gene = Gene.new(:identifier => h[:gene_id], :name => h[:gene_name])
            gene.save
            h_genes[h[:gene_id]] = gene
          end

          h_alleles[h[:identifier]] = {
            :identifier => h[:identifier],
            :gene_id => gene.id,
            :symbol => h[:allele_symbol]
          }
        end
      end
    end
  end
  
  phenotype_allele_file_path =  data_dir + "flybase" + "genotype_phenotype_data_fb_2024_02.tsv.gz"
  #genotype_symbols       genotype_FBids  phenotype_name  phenotype_id    qualifier_names qualifier_ids   reference     
  #064Ya[064Ya]    FBal0119724     chemical sensitive      FBcv:0000440                    FBrf0131396         
  #1.1.3[1.1.3]    FBal0190078     abnormal eye color      FBcv:0000355                    FBrf0190779                                     
  
  header = [:allele_symbol, :identifier, :phenotype_name, :phenotype_id, :qualifier_names, :qualifier_ids, :reference]
  
  h_phenotypes_by_allele = {}
  
  puts "parse #{phenotype_allele_file_path}..."
  File.open(phenotype_allele_file_path, 'rb') do |file|
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
           h_phenotypes_by_allele[h[:identifier]] ||= {}
           h_phenotypes_by_allele[h[:identifier]][h[:phenotype_id]] = {
             :phenotype_name => h[:phenotype_name],
             :qualifier_ids => (h[:qualifier_ids]) ? h[:qualifier_ids].split("|") : nil,
             :qualifier_names => (h[:qualifier_names] != '') ? h[:qualifier_names].split("|") : nil,
             :reference => (h[:reference] != '') ? h[:reference] : nil
           }
         end
       end
    end
  end
  
  puts "Loading..."
  
  h_alleles.each_key do |allele_id|
    h_alleles[allele_id][:phenotypes_json] = ( h_phenotypes_by_allele[allele_id]) ? h_phenotypes_by_allele[allele_id].to_json : nil
    flybase_allele = FlybaseAllele.where(:identifier => allele_id).first
    if !flybase_allele
      flybase_allele = FlybaseAllele.new(h_alleles[allele_id])
       flybase_allele.save
    else
      flybase_allele.update(h_alleles[allele_id])
    end
  end
     
end
