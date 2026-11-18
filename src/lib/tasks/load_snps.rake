desc '####################### load data'
task load_snps: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ##CHROM  POS     ID      REF     ALT   geno_string
  #2L      4998    2L_4998_SNP     G     A 0.00.000.000..000000000..000...0000..0...0000.00..0.00..0.0.00.0000.0.00.00.00..00.0000.00.00.000.0.00000.0..0...000...0.0.0.0.0..0.00..000000.....0200.00.0...0.0.2..020...00.00.020.0..000.0.0..00.2.000.00
  #2L      5002    2L_5002_SNP     G     T 0.00.000.000..000000000..000...0000..0...0000.00..0..0..0.0.0000000.0000.00000..00.0000.00.00.000.0.00000.0..00..000...0.0.0.0.0..0.00..0000000....0000000.0...0.0.0..000...00.00.000.2.0000.0.0..00.0.000.00

  # DGRP3: DGRP2+DGRP3 call set on dm6 (FlyBase r6.64): 4,724,310 variants x 416 lines
  # (212 DGRP lines then 204 RP_xxxx lines, see line 1 of the file and genotyped_lines.dgrp3.txt).
  # Identifiers are already dm6 (CHR_POS_TYPE), so the *_dm6 columns get the same values (map_dm3_to_dm6 is not needed anymore).
  file = data_dir + "dgrp3.genoString.tsv.gz" # DGRP3: was "dgrp2.genoString.tsv" (dm3, 205 lines)

  # Checks done BEFORE anything is deleted: the file is readable, and its line order (line 1) is the one stored in
  # dgrp_lines.geno_index by 'rake load_dgrp_statuses' (which must be run first, on the same file).
  abort "#{file} not found" if !File.exist?(file)
  header_line, column_line, first_line = Zlib::GzipReader.open(file){|f| [f.gets, f.gets, f.gets]}
  file_lines = DgrpLine.parse_geno_header(header_line)
  db_lines = DgrpLine.where.not(:geno_index => nil).order(:geno_index).pluck(:name)
  abort "The line order in #{file} differs from dgrp_lines.geno_index: run 'rake load_dgrp_statuses' first" if file_lines != db_lines
  abort "Unexpected column names in #{file}: #{column_line}" if !column_line.to_s.start_with?("#CHROM")
  abort "No variants in #{file}" if !first_line
  nb_lines = file_lines.size

  # DGRP3: all snp ids change, so gwas_results and snp_genes (which point to snp ids) must be emptied with snps.
  # Destructive, so it only happens with RESET=1:  rake load_snps RESET=1
  # The deletion and the load are in the same transaction: if the load fails (e.g. corrupt file), the old data is kept.
  nb_existing = Snp.count
  abort "snps table is not empty (#{nb_existing} rows). Run 'rake load_snps RESET=1' to delete gwas_results, snp_genes and snps first." if nb_existing > 0 and ENV['RESET'] != '1'

  header = [:chr, :pos, :identifier, :ref, :alt, :geno_string]

  n = 0
  batch = []
  ActiveRecord::Base.transaction do
    if nb_existing > 0
      puts "RESET=1: deleting gwas_results, snp_genes and snps (kept if the load fails)..."
      GwasResult.delete_all
      SnpGene.delete_all
      Snp.delete_all
    end
    File.open(file, 'rb') do |fh|
      Zlib::GzipReader.wrap(fh) do |f|
        f.gets # line names
        f.gets # column names
        while (l = f.gets) do
          t = l.chomp.split("\t")
          raise "Unexpected line in #{file} (#{t.size} columns, geno_string of #{t[5].to_s.size} characters instead of #{nb_lines}): #{l[0, 100]}" if t.size != header.size or t[5].size != nb_lines
          h = {}
          (0 .. t.size-1).to_a.map{|i| h[header[i]] = t[i]}
          h[:pos] = h[:pos].to_i
          h[:chr_dm6] = h[:chr] # DGRP3
          h[:pos_dm6] = h[:pos] # DGRP3
          h[:identifier_dm6] = h[:identifier] # DGRP3
          batch.push h
          if batch.size == 10000 # DGRP3: batched inserts (4.7M rows) instead of one save per row
            Snp.insert_all(batch)
            n += batch.size
            batch = []
            puts "#{n} variants read" if n % 500000 == 0
          end
        end
      end
    end
    Snp.insert_all(batch) if batch.size > 0
    n += batch.size
    nb_loaded = Snp.count
    raise "#{n} variants read but #{nb_loaded} in the snps table (duplicated identifiers?): nothing was changed" if nb_loaded != n
  end
  puts "Done: #{n} variants loaded"

end
