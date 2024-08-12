desc '####################### load_phewas'
task load_phewas: :environment do
  puts 'Executing...'

  
  gwas_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gwas'
  puts "Load snps..."
#  h_snps = {}
#  Snp.all.map{|s| h_snps[s.identifier] = s.id}
  
  h_sex = {
    'F' => 'female',
    'M' => 'male',
    'NA' => 'na'
  }
  puts "Parse files..."
  
  Phenotype.all.each do |p|
    p_attr = p.attributes
    study = p.study
    h_sex.keys.select{|e| p_attr['nber_sex_' + h_sex[e]] > 0}.each do |s|
      prefix = "S#{study.id}_#{p.id}_#{s}"
      
      annot_file = (File.exist?(gwas_dir + "#{prefix}.glm.linear.top_0.001.annot.tsv.gz")) ? "#{prefix}.glm.linear.top_0.001.annot.tsv.gz" : "#{prefix}.glm.logistic.hybrid.top_0.01.annot.tsv.gz"

      # puts annot_file
      if File.exist? gwas_dir + annot_file
        puts annot_file
        gwas_results = GwasResult.where(:phenotype_id => p.id, :sex => s).all
        h_gwas_results = {}
        gwas_results.each do |e|
          h_gwas_results[e.snp_id] = e
        end
        
        File.delete "/tmp/annot.tmp" if File.exist?("/tmp/annot.tmp")
        FileUtils.cp(gwas_dir + annot_file, "/tmp/annot.tmp.gz")
        `gunzip /tmp/annot.tmp.gz`
        #      ActiveRecord::Base.transaction do
        tmp = []
        File.open("/tmp/annot.tmp", 'r') do |f|
          header = f.gets
        #  puts header
          while (l = f.gets) do
            t = l.split("\t")
            #         puts t
            identifier = t[2]
            p_val = t[6]
            fdr = t[7]
            h_gwas_result = {
              :p_val => t[6],
              :fdr => t[7],
              #             :snp_id => h_snps[t[2]], #Snp.where(:identifier => t[2]).first.id,
              :identifier => t[2], #Snp.where(:identifier => t[2]).first.id,
              :phenotype_id => p.id,
              :sex => s
            }
            tmp.push h_gwas_result
          end
        end
        #        puts tmp.to_json
        h_snps = {}
        Snp.where(:identifier => tmp.map{|e| e[:identifier]}).all.map{|s| h_snps[s.identifier] = s.id}
        
        #          puts h_gwas_result.to_json
        #          exit
        tmp.each do |h_gwas_result|
          h_gwas_result[:snp_id] = h_snps[h_gwas_result[:identifier]]
          h_gwas_result.delete(:identifier)
          #  gwas_result = GwasResult.where(h_gwas_result).first
          gwas_result = h_gwas_results[h_gwas_result[:snp_id]]
          if !gwas_result           
            gwas_result = GwasResult.new(h_gwas_result)
            #           puts gwas_result.to_json
            gwas_result.save
            #           puts gwas_result
            #            exit
          elsif h_gwas_result[:p_val] != gwas_result.p_val or h_gwas_result[:fdr] != gwas_result.fdr
            gwas_result.update(h_gwas_result)
          end
          #          exit
          #          puts t[6] + ", " + t[7]
          #          puts t[8]
          #   b = t[9].split(";")
          #   sites = []
          #   b.each do |e|
          #     if m = e.match(/\((.+?)\)/)
          #       sites.push(m[1])
          #     end
          #   end
          #          puts sites.to_json
        end
        #   end
        #        exit
      end
      #    end
    end
    
  end
  
  
end

