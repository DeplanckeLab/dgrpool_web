desc '####################### fix_dgrp_line_studies_phenotypes'
task fix_dgrp_line_studies_phenotypes: :environment do
  puts 'Executing...'


  def add_assoc h, p, h_dgrp_line_studies

    h.each_key do |dgrp_line|
      if h[dgrp_line][p.name] and h[dgrp_line][p.name].compact.size > 0
        dgrp_line_study = h_dgrp_line_studies[dgrp_line]
        if !p.dgrp_line_studies.include? dgrp_line_study
          p.dgrp_line_studies << dgrp_line_study 
#          puts "add association #{dgrp_line_study.id} to #{p.id}: #{h[dgrp_line][p.name].to_json}"
        end
      end
    end
  end

  h_dgrp_lines = {}
  DgrpLine.all.map{|e| h_dgrp_lines[e.id] = e}
    
  Study.all.each do |s|
    puts s.id
    h = Basic.safe_parse_json(s.pheno_json, {})
    h_dgrp_line_studies = {}
    DgrpLineStudy.where(:study_id => s.id).map{|e| h_dgrp_line_studies[h_dgrp_lines[e.dgrp_line_id].name] = e}
    
    s.phenotypes.each do |phenotype|

      if h["summary"]
        add_assoc(h["summary"], phenotype, h_dgrp_line_studies)
      end
      if h['raw']
        h['raw'].each_key do |k| 
          add_assoc(h['raw'][k], phenotype, h_dgrp_line_studies)
        end
      end
      
    end
  end
  
end

