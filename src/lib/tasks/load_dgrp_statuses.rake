desc '####################### load dgrp statuses'
task load_dgrp_statuses: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  DgrpLine.all.update_all(:dgrp_status_id => 3)
  
  file = data_dir + "genotyped_dgrp_lines.txt"
  File.open(file, "r") do |f|
    while(l = f.gets) do
      v = l.chomp#.split(" ").first
      dgrp_number = v.gsub(/line_/, '')
      identifier = "DGRP_" + ("0" * (3-dgrp_number.size)) + dgrp_number
      puts identifier
      d = DgrpLine.find_by_name(identifier)
      d.update(:dgrp_status_id => 2)
    end
  end

  file = data_dir + "available_dgrp_lines.txt"
  File.open(file, "r") do |f|
    while(l = f.gets) do
      v = l.chomp
      puts v
      dgrp_number = v.gsub(/DGRP-/, '')
      puts dgrp_number
      identifier = "DGRP_" + ("0" * (3-dgrp_number.size)) + dgrp_number
      puts identifier
      d = DgrpLine.find_by_name(identifier)
      d.update(:dgrp_status_id => 1)
    end
  end

end
