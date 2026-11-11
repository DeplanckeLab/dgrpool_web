desc '####################### backfill_sex_by_dgrp'
task backfill_sex_by_dgrp: :environment do
  ## rebuild phenotypes.sex_by_dgrp for every study from pheno_sum_json (idempotent)
  puts 'Executing...'
  total = 0
  Study.order(:id).each do |study|
    begin
      n = Basic.upd_sex_by_dgrp(study)
      total += n
      puts "Study #{study.id}: #{n} phenotypes updated" if n > 0
    rescue => e
      puts "Study #{study.id}: ERROR #{e.class}: #{e.message}"
    end
  end
  puts "Finished: #{total} phenotypes updated"
end
