desc '####################### load dgrp statuses'
task load_dgrp_statuses: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  DgrpLine.all.update_all(:dgrp_status_id => 3)
  
  file = data_dir + "genotyped_dgrp_lines.txt"
  File.open(file, "r") do |f|
    while(l = f.gets) do
      v = l.chomp#.split(" ").first
      identifier = DgrpLine.normalize_name(v)
      puts identifier
      d = DgrpLine.find_by_name(identifier)
      d.update(:dgrp_status_id => 2) if d
    end
  end

  file = data_dir + "available_dgrp_lines.txt"
  File.open(file, "r") do |f|
    while(l = f.gets) do
      v = l.chomp
      puts v
      identifier = DgrpLine.normalize_name(v)
      puts identifier
      d = DgrpLine.find_by_name(identifier)
      d.update(:dgrp_status_id => 1) if d
    end
  end

end
