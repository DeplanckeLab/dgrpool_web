desc '####################### load_bloomington'
task load_bloomington: :environment do
  puts 'Executing...'
  
  file = Pathname.new(APP_CONFIG[:data_dir]) + 'dgrp_stock.txt'

  #DGRP    Stock
  #DGRP_208        25174
  #DGRP_301        25175
  #DGRP_303        25176

  h = {}
 DgrpLine.all.map{|e| h[e.name] = e}
  
  File.open(file, 'r') do |f|
    header = f.gets
    while(l = f.gets) do
      t = l.split("\t")
      h[t[0]].update({:bloomington_id => t[1].to_i})
    end  
  end
  
  
end

