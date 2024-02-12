desc '####################### load_annots'
task load_annots: :environment do
  puts 'Executing...'

  
  gwas_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gwas'
  snp_file = gwas_dir + ''
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
      
      annot_file = (File.exist?(gwas_dir + "#{prefix}.glm.linear.top_0.01.annot.tsv.gz")) ? "#{prefix}.glm.linear.top_0.01.annot.tsv.gz" : "#{prefix}.glm.logistic.hybrid.top_0.01.annot.tsv.gz"

      # puts annot_file
      if File.exist? gwas_dir + annot_file
        puts annot_file
        gwas_results = GwasResult.where(:phenotype_id => p.id, :sex => s).all
        h_snps = {}
        snps = Snp.where(:id => gwas_results.map{|e| e.snp_id}).all
        snps.each do |e|
          h_snps[e.identifier] = e
        end
        
        File.delete "/tmp/annot.tmp" if File.exist?("/tmp/annot.tmp")
        FileUtils.cp(gwas_dir + annot_file, "/tmp/annot.tmp.gz")
        `gunzip /tmp/annot.tmp.gz`
        #      ActiveRecord::Base.transaction do
        tmp = []
        i=0
        File.open("/tmp/annot.tmp", 'r') do |f|
          header = f.gets
        #  puts header
          while (l = f.gets) do
            t = l.split("\t")
            #                     puts t
            if h_snps[t[2]] #and !h_snps[t[2]].annots_json
              h = {:transcript_annot=> {}, :binding_site_annot => {}}
              #            puts "8: " + t[8]
              t[8].split(",").each do |e|
                #              puts "->" + e
                if m = e.match(/^(\w+)\[(.+)\]$/)
                  if m[1] == 'TranscriptAnnot'
                    l = m[2].split(";")
                    l.each do |e2|
                      #                   puts "--->" + m[1] + " => " + e2
                      if m2 = e2.match(/^(\w+)\((.+)\)$/)
                        l2 = m2[2].split("|")
                        #                     puts "-------->#{m2[1]} => #{l2[0]}, #{l2[1]}, #{l2[5]}"
                        h[:transcript_annot][m2[1]] ||= {}
                        h[:transcript_annot][m2[1]][l2[5]] ||= []
                        h[:transcript_annot][m2[1]][l2[5]].push l2[8] if !h[:transcript_annot][m2[1]][l2[5]].include? l2[8]
                      end
                    end
                    #                  h[m[1]] = l
                  end
                end
              end
              #            puts "9: " + t[9]
              t[9].split(";").each do |e|
                if m = e.match(/^\((.+)\)$/)
                  #                puts "->" + m[1]
                  t2 = m[1].split("|")
                  #                puts "->" + t2[0] + " : " + t2[1]
                  h[:binding_site_annot][t2[0]]||={}
                   h[:binding_site_annot][t2[0]][t2[1]]||=[]
                  h[:binding_site_annot][t2[0]][t2[1]].push t2[2] if !h[:binding_site_annot][t2[0]][t2[1]].include? t2[2]
                end
              end
              #            puts h.to_json
              #            puts t[2]

              if h_snps[t[2]]
                h_snps[t[2]].update({:annots_json => h.to_json})
              else
                puts "Variant #{t[2]} not found!!!"
              end
            end
            #            i+=1
#            exit if i > 10
          end
        end
          
      end
      #    end
    end
    
  end
  
  
end

