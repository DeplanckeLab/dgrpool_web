desc '####################### load dgrp statuses'
task load_dgrp_statuses: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  # DGRP3: the genotyped lines are the 416 lines of dgrp3.genoString.tsv.gz (212 DGRP + 204 DGRP3 'RP_xxxx').
  # Line 1 of that file gives the order of the geno_string characters: it is stored in dgrp_lines.geno_index,
  # which phenotypes_controller uses to map geno_string characters to lines (statuses are only for display).
  # Names go through DgrpLine.normalize_name (line_21 / DGRP-21 / DGRP_021 -> DGRP_021 ; RP-0002 / RP_2 -> RP_0002)
  geno_file = data_dir + "dgrp3.genoString.tsv.gz"
  abort "#{geno_file} not found" if !File.exist?(geno_file)
  header_line = Zlib::GzipReader.open(geno_file){|f| f.gets}
  genotyped = DgrpLine.parse_geno_header(header_line)
  abort "Line 1 of #{geno_file} contains invalid line names" if genotyped.empty? or genotyped.include?(nil)
  abort "Line 1 of #{geno_file} contains duplicated line names" if genotyped.uniq.size != genotyped.size

  # cross-check with the list of genotyped lines (catches files from different releases)
  list_file = data_dir + "genotyped_lines.dgrp3.txt" # DGRP3: was genotyped_dgrp_lines.txt (205 lines)
  if File.exist?(list_file)
    listed = File.readlines(list_file).map{|l| DgrpLine.normalize_name(l) || l.strip}.reject(&:empty?)
    abort "#{list_file} and line 1 of #{geno_file} do not contain the same lines" if listed.sort != genotyped.sort
  end

  available = File.readlines(data_dir + "available_dgrp_lines.txt").map{|l| DgrpLine.normalize_name(l) || l.strip}.reject(&:empty?)

  h_lines = {}
  DgrpLine.all.map{|d| h_lines[d.name] = d}
  missing = genotyped.select{|name| !h_lines[name]}
  abort "#{missing.size} genotyped lines are not in dgrp_lines (create them first, e.g. rake load_bloomington): #{missing.join(', ')}" if missing.size > 0

  ActiveRecord::Base.transaction do
    # statuses as before DGRP3: available (1) > genotyped (2) > unavailable (3)
    DgrpLine.all.update_all(:dgrp_status_id => 3)
    DgrpLine.where(:name => genotyped).update_all(:dgrp_status_id => 2)
    DgrpLine.where(:name => available).update_all(:dgrp_status_id => 1)

    DgrpLine.where.not(:geno_index => nil).update_all(:geno_index => nil)
    genotyped.each_with_index{|name, i| h_lines[name].update_columns(:geno_index => i)}
  end

  not_genotyped = available - genotyped
  puts "#{genotyped.size} genotyped lines (geno_index 0..#{genotyped.size-1}), #{(available & genotyped).size} of them available"
  puts "#{not_genotyped.size} available lines are not genotyped: #{not_genotyped.join(', ')}" if not_genotyped.size > 0

end
