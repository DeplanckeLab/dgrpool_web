desc '####################### map_dm3_to_dm6'
task map_dm3_to_dm6: :environment do
  puts 'Executing...'

  
  dm6_annot_file = Pathname.new(APP_CONFIG[:data_dir]) + 'dgrp2.dm6.vcf.gz'
  chrs = ["2L", "2R", "3L", "3R", "4", "X", "Y"]
  h_chrs = {}
  chrs.map{|c| h_chrs[c] = 1}
  ##contig=<ID=2L,length=23513712>
##contig=<ID=2R,length=25286936>
##contig=<ID=3L,length=28110227>
##contig=<ID=3R,length=32079331>
##contig=<ID=4,length=1348131>
##contig=<ID=X,length=23542271>
##contig=<ID=Y
  h_sex = {
    'F' => 'female',
    'M' => 'male',
    'NA' => 'na'
  }

  puts "Load snps"
  h_snps = {}
  Snp.all.map{|s| h_snps[s.identifier] = s}

  puts "Parse files..."

  h_map = {}

  
# ActiveRecord::Base.transaction do
#  begin
  File.open(dm6_annot_file, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      #2L      11369   2L_11369_SNP    G       A       999     PASS
      
      gz.each_line do |l|
#        puts l
        if !l.match(/^\#/)
 
          t = l.split("\t")
          identifier = t[2]
          identifier_parts = t[2].split("_")
 #         puts identifier_parts
          if h_chrs[t[0]] and h_snps[t[2]]
            h_snps[t[2]].update(:chr_dm6 => t[0], :pos_dm6 => t[1], :identifier_dm6 => [t[0], t[1], identifier_parts[2]].join("_"))
#            puts [t[0], t[1], identifier_parts[2]].join("_")
          end
        else
       #   puts l
        end
      end
    end
    
  end
#   rescue StandardError => e
#    puts "Error occurred: #{e.message}"
#  end
# end  
  
end
