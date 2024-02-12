desc '####################### fix_phenotype_name'
task fix_phenotype_name: :environment do
  puts 'Executing...'


  def upd_phenotype_name h_pheno

    h_keys = {}
    h_pheno.each_key do |dgrp_line|
      h_pheno[dgrp_line].each_key do |p|
        if p != p.strip
          h_keys[p]=1
    #      h_pheno[dgrp_line][p.strip] =  h_pheno[dgrp_line][p].dup
    #      h_pheno[dgrp_line].delete(p)
        end
      end
    end

    h_keys.each_key do |p|
      puts "#{p} => #{p.strip}"
      h_pheno.each_key do |dgrp_line|
        #        if h_pheno[dgrp_line][p]
        h_pheno[dgrp_line][p.strip] = ( h_pheno[dgrp_line][p]) ? h_pheno[dgrp_line][p].dup : nil
        h_pheno[dgrp_line].delete(p)  
        #        end
      end
    end

    return h_pheno
    
  end
  
  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ## compute dgrp_lines stats
  
  dgrp_lines = DgrpLine.all
  
  h_studies = {}
#  studies = Study.where(:id => 79).all
studies = Study.all
  studies.map{|s| h_studies[s.id] = s}

#  h_pheno_stats = {:nber_dgrp_lines => {}}
  
  h_phenotypes = {}
#  h_phenos_by_name = {}
  Phenotype.all.map{|p|
    h_phenotypes[p.id] = p
#    h_phenos_by_name[p.name] = p
#    h_pheno_stats[:nber_dgrp_lines][p.name] = 0
  }

  studies.each do |s|
    h_pheno = Basic.safe_parse_json(s.pheno_json, {})
    if h_pheno['summary']
      h_pheno['summary'] = upd_phenotype_name(h_pheno['summary'])
    end
    if  h_pheno['raw']
      h_pheno['raw'].each_key do |k|
        h_pheno['raw'][k] = upd_phenotype_name(h_pheno['raw'][k])
      end
    end
#    puts h_pheno.to_json
#    exit
    s.update(:pheno_json => h_pheno.to_json)

    if File.exist?(data_dir + 'studies' + s.id.to_s)

      ## fix symlinks
      Dir.entries(data_dir + 'studies' + s.id.to_s).select{|e| File.symlink?(data_dir + 'studies' + s.id.to_s + e) and  e.match(/\.tsv$/)}.each do |filename|
        if target = File.readlink(data_dir + 'studies' + s.id.to_s + filename)
          t_target = target.split("/")
          if t_target.size == 5
            t_target.push(t_target.last)
            t_target[4] = s.id.to_s
            puts t_target.join("/")
            puts "delete #{data_dir + 'studies' + s.id.to_s + filename}"
            File.delete(data_dir + 'studies' + s.id.to_s + filename)
            puts "create symlink: #{data_dir + 'studies' + s.id.to_s + filename}, #{t_target.join("/")}"
            File.symlink(t_target.join("/"), data_dir + 'studies' + s.id.to_s + filename)
          end
        end
      end

      Dir.entries(data_dir + 'studies' + s.id.to_s).select{|e| !File.symlink?(data_dir + 'studies' + s.id.to_s + e) and  e.match(/\.tsv$/)}.each do |filename|
        File.open(data_dir + 'tmp.tsv', 'w') do |fw|
          File.open(data_dir + 'studies' + s.id.to_s + filename, 'r') do |f|
            header = f.gets.chomp
            t_header = header.split("\t")
            fw.write(t_header.map{|e| e.strip}.join("\t") + "\n")
            while (l = f.gets) do
              fw.write(l)
            end          
          end
        end
        FileUtils.move(data_dir + 'tmp.tsv', data_dir + 'studies' + s.id.to_s + filename)
      end
    end
    
    
  end
  
end

