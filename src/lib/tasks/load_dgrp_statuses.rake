desc '####################### load dgrp statuses'
task load_dgrp_statuses: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  # DGRP3: the genotyped lines are now the 416 lines of dgrp3.genoString.tsv.gz (212 DGRP + 204 DGRP3 'RP_xxxx').
  # phenotypes_controller maps geno_string characters to DgrpLine.where(:dgrp_status_id => [1,2]) sorted by name,
  # so the lines with status 1/2 must be exactly these 416 lines, in this order. This task checks it and rolls back otherwise.
  # Names go through DgrpLine.normalize_name (line_21 / DGRP-21 / DGRP_021 -> DGRP_021 ; RP-0002 / RP_2 -> RP_0002)
  normalize = lambda { |v| DgrpLine.normalize_name(v) || v.strip }

  genotyped = File.readlines(data_dir + "genotyped_lines.dgrp3.txt").map{|l| normalize.call(l)}.reject(&:empty?) # DGRP3: was genotyped_dgrp_lines.txt (205 lines)
  available = File.readlines(data_dir + "available_dgrp_lines.txt").map{|l| normalize.call(l)}.reject(&:empty?)

  h_lines = {}
  DgrpLine.all.map{|d| h_lines[d.name] = d}
  missing = genotyped.select{|name| !h_lines[name]}
  abort "#{missing.size} genotyped lines are not in dgrp_lines (create them first, e.g. rake load_bloomington): #{missing.join(', ')}" if missing.size > 0

  h_genotyped = {}
  genotyped.each{|name| h_genotyped[name] = true}
  not_genotyped = available.select{|name| !h_genotyped[name]}
  # DGRP3: an available line that is not genotyped used to get status 1, which shifts the geno_string mapping; it now stays at 3
  puts "WARNING: #{not_genotyped.size} available lines are not genotyped and keep status 3: #{not_genotyped.join(', ')}" if not_genotyped.size > 0

  ActiveRecord::Base.transaction do
    DgrpLine.all.update_all(:dgrp_status_id => 3)
    DgrpLine.where(:name => genotyped).update_all(:dgrp_status_id => 2)
    DgrpLine.where(:name => available & genotyped).update_all(:dgrp_status_id => 1)

    ordered = DgrpLine.where(:dgrp_status_id => [1,2]).all.map(&:name).sort
    raise "Lines with status 1/2 (sorted by name) do not match genotyped_lines.dgrp3.txt; nothing was changed" if ordered != genotyped
  end
  puts "#{genotyped.size} genotyped lines, #{(available & genotyped).size} of them available"

end
