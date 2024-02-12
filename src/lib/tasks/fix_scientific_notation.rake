desc '####################### fix_scientific_notation'
task fix_scientific_notation: :environment do
  puts 'Executing...'


  Study.all.each do |s|
    puts s.id
    flag = 0
    h = Basic.safe_parse_json(s.pheno_json, {})
#    s.phenotypes.each do |phenotype|
    if h['summary']
      h['summary'].each_key do |k|
        phenos =  h["summary"][k].keys.sort - ["sex"]
        phenos.each do |phenotype|
          if h["summary"][k][phenotype]
            h["summary"][k][phenotype].each_index do |i|
              e = h["summary"][k][phenotype][i]
              if e.is_a? String and e.match(/^-?\d+\.?\d*?[eE][\-+]?\d+$/)
                puts "Change text to float for #{phenotype} in study #{s.id}"
                h["summary"][k][phenotype][i] = e.to_f
                flag = 1
              end
            end
          end
        end
      end
      if h['raw']
        h['raw'].each_key do |k2|
          h['raw'][k2].each_key do |k|
            phenos = h["raw"][k2][k].keys.sort - ["sex"]
            phenos.each do |phenotype|
              if  h["raw"][k2][k][phenotype]
                h["raw"][k2][k][phenotype].each_index do |i|
                  e = h["raw"][k2][k][phenotype][i]
                  if e.is_a? String and e.match(/^-?\d+\.?\d*?[eE][\-+]?\d+$/)
                    puts "Change text to float for #{phenotype} in study #{s.id}"
                    h["raw"][k2][k][phenotype][i] = e.to_f
                    flag = 1
                  end
                end
              end
            end
          end
        end
      end
    end
    
    s.update(:pheno_json => h.to_json) if flag == 1 or s.id == 20
  end
  
end

