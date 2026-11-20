desc '####################### load_phewas'
task load_phewas: :environment do
  puts 'Executing...'

  ## DGRP3: 6,538 result files, 9.55M rows (largest file: 82k rows), vs 2M rows for DGRP2. Compared to the previous version:
  ##  - new rows are written with insert_all (batches of 10,000) instead of one save per row;
  ##  - snps and existing results are read with pluck (no ActiveRecord objects, no geno_string/annots_json);
  ##  - p-values are compared as floats (they were compared as string vs float, so a rerun rewrote every row);
  ##  - the file is streamed with zcat instead of being copied and gunzipped to a fixed /tmp path.
  ## Memory stays bounded by one phenotype/sex file. Rerunnable: existing rows are kept, changed ones updated.
  ## Variants absent from the snps table are skipped; results of a phenotype/sex not in the new file are deleted.

  gwas_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gwas'

  h_sex = {
    'F' => 'female',
    'M' => 'male',
    'NA' => 'na'
  }
  batch_size = 10000
  nb_files = 0
  nb_inserted = 0
  nb_updated = 0
  nb_deleted = 0
  puts "Parse files..."

  ## optional: PHENOTYPE_IDS=3946,8354 to (re)load only these phenotypes
  phenotypes = (ENV['PHENOTYPE_IDS']) ? Phenotype.where(:id => ENV['PHENOTYPE_IDS'].split(",").map(&:to_i)) : Phenotype.all
  phenotypes.each do |p|
    p_attr = p.attributes
    h_sex.keys.select{|e| p_attr['nber_sex_' + h_sex[e]].to_i > 0}.each do |s|
      prefix = "S#{p.study_id}_#{p.id}_#{s}"
      annot_file = (File.exist?(gwas_dir + "#{prefix}.glm.linear.top_0.001.annot.tsv.gz")) ? "#{prefix}.glm.linear.top_0.001.annot.tsv.gz" : "#{prefix}.glm.logistic.hybrid.top_0.001.annot.tsv.gz"
      next if !File.exist?(gwas_dir + annot_file)
      nb_files += 1

      ## identifier => [p_val, fdr] (the file is sorted by p-value, so the first occurrence is kept)
      h_file = {}
      IO.popen(["zcat", (gwas_dir + annot_file).to_s]) do |f|
        f.gets # header
        while (l = f.gets) do
          t = l.split("\t", 9)
          h_file[t[2]] ||= [Float(t[6], exception: false), Float(t[7], exception: false)]
        end
      end
      raise "zcat failed on #{annot_file}" if !$?.success?

      h_snps = {}
      h_file.keys.each_slice(batch_size){|ids| Snp.where(:identifier => ids).pluck(:identifier, :id).each{|i, id| h_snps[i] = id}}
      missing = h_file.keys.select{|i| !h_snps[i]}
      puts "#{annot_file}: WARNING: #{missing.size} variants not in snps table, skipped (e.g. #{missing.first})" if missing.size > 0

      ## snp_id => [id, p_val, fdr]
      h_existing = {}
      GwasResult.where(:phenotype_id => p.id, :sex => s).pluck(:snp_id, :id, :p_val, :fdr).each{|snp_id, id, pv, fdr| h_existing[snp_id] = [id, pv, fdr]}

      new_rows = []
      seen_snp_ids = {}
      h_file.each do |identifier, (p_val, fdr)|
        snp_id = h_snps[identifier]
        next if !snp_id
        seen_snp_ids[snp_id] = true
        if e = h_existing[snp_id]
          if e[1] != p_val or e[2] != fdr
            GwasResult.where(:id => e[0]).update_all(:p_val => p_val, :fdr => fdr)
            nb_updated += 1
          end
        else
          new_rows.push({:snp_id => snp_id, :phenotype_id => p.id, :sex => s, :p_val => p_val, :fdr => fdr})
        end
      end
      new_rows.each_slice(batch_size){|rows| GwasResult.insert_all(rows)}
      nb_inserted += new_rows.size

      ## results of this phenotype/sex that are not in the new file anymore (e.g. old dm3 rows, rows with snp_id = nil)
      stale_ids = h_existing.keys.select{|id| !seen_snp_ids[id]}
      if stale_ids.size > 0
        nb_deleted += GwasResult.where(:phenotype_id => p.id, :sex => s, :snp_id => stale_ids).delete_all
      end

      puts "#{nb_files} files: #{nb_inserted} inserted, #{nb_updated} updated, #{nb_deleted} deleted" if nb_files % 200 == 0
    end
  end
  puts "Done: #{nb_files} files: #{nb_inserted} inserted, #{nb_updated} updated, #{nb_deleted} deleted; #{GwasResult.count} gwas_results in total"

end
