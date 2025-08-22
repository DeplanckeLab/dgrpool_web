desc '####################### load_bloomington'
task load_bloomington: :environment do
  puts 'Executing...'

  # download (copy paste table in file) file from https://bdsc.indiana.edu/stocks/wt/dgrp.html
  # could also use https://s3ftp.flybase.org/releases/FB2025_03/precomputed_files/stocks/index.html
  
  file = Pathname.new(APP_CONFIG[:data_dir]) + 'dgrp_stock2.txt'
  

  
  #DGRP    Stock
  #DGRP_208        25174
  #DGRP_301        25175
  #DGRP_303        25176

  h = {}
 DgrpLine.all.map{|e| h[e.name] = e}
  
  File.open(file, 'r') do |f|
    header = f.gets
    while(l = f.gets) do
      t = l.split(/\s+/)
      #      key = t[1].gsub(/DGRP-/, "DGRP_").gsub(/RP-/, "DGRP-3-")
      #       new_name = key.gsub(/DGRP-3-/, "RP_")
      key =  key = t[1].gsub(/DGRP-/, "DGRP_").gsub(/RP-/, "RP_")
      if m = key.match(/DGRP_(.+)/)
        key = "DGRP_" + ('0' * (3-m[1].size))  + m[1]
      end

      puts key
      if h[key] and t[0].to_i
        puts "Set #{key} => #{t[0]}"
      #h[key].update({:bloomington_id => t[0].to_i})
        #pputs 
      else
        h_dgrp = {
          :name => key,
          :bloomington_id => t[0].to_i,
          :dgrp_status_id => 3,
          :user_id => 1,
          :nber_studies => 0,
          :nber_phenotypes => 0          
        }
        d = DgrpLine.new(h_dgrp)
        #d.save
        puts d.to_json
      end
    end  
  end
  
  
end

