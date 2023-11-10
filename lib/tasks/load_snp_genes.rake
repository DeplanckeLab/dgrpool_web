desc '####################### load_snp_genes'
task load_snp_genes: :environment do
  puts 'Executing...'

 # h_impact = {
 #   'HIGH' => 'danger',
 #   'MODERATE' => 'warning',
 #   'LOW' => 'secondary',
 #   'MODIFIER' => 'info'
 # }

 # h_impact.each_key do |impact_name|
 #   snp_impact = SnpImpact.where(:name => impact_name).first
 #   if !snp_impact
 #     snp_impact = SnpImpact.new(:name => impact_name)
 #     snp_impact.save
 #   end
 # end

  ## loading existing
  puts "loading existing objects..."
  
  h_var_types = {}
  VarType.all.map{|e| h_var_types[e.name] = e}
#  h_snp_impacts = {}
#  SnpImpact.all.map{|e| h_snp_impacts[e.id] = e}
  h_genes = {}
  Gene.all.map{|g| h_genes[g.name] = g}
  h_snp_genes = {}
  SnpGene.all.map{|sg| h_snp_genes[[sg.snp_id, sg.gene_id]] = sg}

  puts "start/continuing parsing..."

  last_id = Snp.last.id
 # puts "Last ID: #{last_id}"
  size_page = 1000
  (0 .. (last_id/size_page + 1)).to_a.each do |page|
  
    #  i = 0
    Snp.where("id > #{page * size_page} and id <= #{(page + 1) * size_page}").all.each do |snp|
   #   puts "SNP: #{snp.id}"
      #   ActiveRecord::Base.transaction do
      
      # @h_snps[t[2]]['transcript_annot'].keys.map{|k| display_var_type(t[2], @h_var_types[k], @h_snps[t[2]]['transcript_annot'][k])}.join("<br/>")
      h_snps = Basic.safe_parse_json(snp.annots_json, {})
      if  h_snps['transcript_annot']
        h_snps['transcript_annot'].each_key do |k|
   #       puts "-> #{k}"
          h_snps['transcript_annot'][k].each do |gene_name|
            if gene_name[0] != ''
  #            puts "--> gene_name:#{gene_name}"

              gene = h_genes[gene_name[0]]
              if !gene
                gene = Gene.new({:name => gene_name[0]})
                gene.save
                
                h_genes[gene_name[0]] = gene
              end

              if gene and !h_snp_genes[[snp.id, gene.id]] and var_type = h_var_types[k]
                #snp_type_id int references snp_types,
                #snp_impact_id int references snp_impacts,
                #affects_regulatory_regions bool,
                #affects_binding_sites bool,
                
                #h_snps['binding_site_annot']
 #               puts h_snps['binding_site_annot'].to_json
                h_snp_gene = {
                  :snp_id => snp.id,
                  :gene_id => gene.id,
                  :var_type_id => var_type.id,
                  #               :snp_impact_id => snp_impact.id,
                  :affects_regulatory_region => (h_snps['binding_site_annot']['regulatory_region']) ? true : false,
                  :affects_tf_binding_site => (h_snps['binding_site_annot']['TF_binding_site']) ? true : false
                }
                
                if !h_snp_genes[[snp.id, gene.id]]
                  
                  snp_gene = SnpGene.new(h_snp_gene)
                  snp_gene.save
#                  puts "create #{snp_gene.to_json}"
                  h_snp_genes[[snp.id, gene.id]] = snp_gene
                  
                end
              end
            end
          end
        end
        #   end
      end
      
      #   i+=1
      #   exit if i >10 
    
    end
  end
    
  
end

