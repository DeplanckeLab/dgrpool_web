desc '####################### load data'
task load_snps: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  
  ##CHROM  POS     ID      REF     ALT   geno_string
  #2L      4998    2L_4998_SNP     G     A 0.00.000.000..000000000..000...0000..0...0000.00..0.00..0.0.00.0000.0.00.00.00..00.0000.00.00.000.0.00000.0..0...000...0.0.0.0.0..0.00..000000.....0200.00.0...0.0.2..020...00.00.020.0..000.0.0..00.2.000.00
  #2L      5002    2L_5002_SNP     G     T 0.00.000.000..000000000..000...0000..0...0000.00..0..0..0.0.0000000.0000.00000..00.0000.00.00.000.0.00000.0..00..000...0.0.0.0.0..0.00..0000000....0000000.0...0.0.0..000...00.00.000.2.0000.0.0..00.0.000.00

  file = data_dir + "dgrp2.genoString.tsv"

  header = [:chr, :pos, :identifier, :ref, :alt, :geno_string]

  ActiveRecord::Base.transaction do
    File.open(file, 'r') do |f|
      f.gets
      f.gets
      while (l = f.gets) do
#        puts l
        t = l.chomp.split("\t")
        h = {}
        (0 .. t.size-1).to_a.map{|i| h[header[i]] = t[i]}
        s = Snp.new(h)
        s.save
        
      end
    end
  end
    
end
