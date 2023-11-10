desc '####################### fix_pheno_type'
task fix_pheno_type: :environment do
  puts 'Executing...'


  Study.all.each do |s|
    puts s.id
    h = Basic.safe_parse_json(s.pheno_json, {})
    s.phenotypes.each do |phenotype|
      if h['summary']
         is_numeric = true
         h['summary'].keys.select{|k| h["summary"][k][phenotype.name]}.map{|k| h["summary"][k][phenotype.name].each_index{|i|
                                                                             e = h["summary"][k][phenotype.name][i]
                                                                             if e == 'NA'
                                                                               e = nil
                                                                               h["summary"][k][phenotype.name][i] = nil
                                                                             end
                                                                             if !e.is_a? Numeric and e != nil
                                                                               is_numeric = false
                                                                        #       puts phenotype.name + " <" + e + ">"
                                                                             end
                                                                           }
         }
        if phenotype.is_numeric != is_numeric
          puts "#{phenotype.name} => move to #{is_numeric}"
          phenotype.update(:is_numeric => is_numeric)
        end
        if phenotype.is_numeric == false
          puts "#{phenotype.name} is TEXT"
        end
      end
      if h['raw']
        if h['raw'].each_key do |k2|
             is_numeric = true
             h['raw'][k2].keys.select{|k| h["raw"][k2][k][phenotype.name]}.map{|k| h["raw"][k2][k][phenotype.name].each_index{|i|
                                                                                 e = h["raw"][k2][k][phenotype.name][i]
                                                                                 if e == 'NA'
                                                                                   e = nil
                                                                                   h["raw"][k2][k][phenotype.name][i] = nil
                                                                                 end
                                                                                 
                                                                                 if e != nil and !e.is_a? Numeric
                                                                                   is_numeric = false
                                                                                 end
                                                                               }
             }
             if phenotype.is_numeric != is_numeric
               puts "#{phenotype.name} => move to #{is_numeric}"
               phenotype.update(:is_numeric => is_numeric)
             end
             if phenotype.is_numeric == false
               puts "#{phenotype.name} is TEXT"
             end
             
           end
        end
      end
      
    end
    
    
    s.update(:pheno_json => h.to_json)
  end
  
end

