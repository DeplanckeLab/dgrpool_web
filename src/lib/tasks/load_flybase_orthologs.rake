desc '####################### load flybase_orthologs'
task load_flybase_orthologs: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  h_orthologs = {}

  h_genes = {}
  Gene.all.map{|g| h_genes[g.identifier] = g; h_genes[g.name] = g}
  
  orthologs_file_path = data_dir + "flybase" + "dmel_human_orthologs_disease_fb_2024_02.tsv.gz"
 
  ##Dmel_gene_ID  Dmel_gene_symbol        Human_gene_HGNC_ID      Human_gene_OMIM_ID      Human_gene_symbol       DIOPT_score     OMIM_Phenotype_IDs      OMIM_Phenotype_IDs[name]
  #FBgn0031081     Nep3    HGNC:8918       OMIM:300550     PHEX    5       307800  307800[HYPOPHOSPHATEMIC RICKETS, X-LINKED DOMINANT; XLHR]
  #FBgn0031081     Nep3    HGNC:14668      OMIM:618104     MMEL1   8               

  header = [:gene_identifier, :gene_name, :hgnc_gene_id, :omim_gene_id, :human_gene_name, :diopt_score, :omim_phenotype_ids, :omim_phenotypes]
  
  puts "parse #{orthologs_file_path}..." 
  File.open(orthologs_file_path, 'rb') do |file|
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

          gene = Gene.where(:identifier => h[:gene_identifier]).first
          if t.size > 1 and gene
            puts line
            hgnc_gene_id = h[:hgnc_gene_id].split(":")[1]
            h_human_ortholog = {
              :gene_id => gene.id,
              :hgnc_gene_id => hgnc_gene_id,
              :omim_gene_id => h[:omim_gene_id].split(":")[1],
              :human_gene_name => h[:human_gene_name],
              :diopt_score => h[:diopt_score],
              :omim_phenotypes => h[:omim_phenotypes]
            }

            human_ortholog = HumanOrtholog.where(:gene_id => gene.id, :hgnc_gene_id => hgnc_gene_id).first
            if !human_ortholog
              human_ortholog = HumanOrtholog.new(h_human_ortholog)
              human_ortholog.save
            else
              human_ortholog.update(h_human_ortholog)
            end
            
          end
        end
      end
    end
  end
  
end
