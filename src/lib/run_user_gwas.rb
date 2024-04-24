require 'pathname'

#ENV.each do |key, value|
#  puts "#{key}: #{value}"
#end

lines = File.readlines(".env")
lines.map{|e| t = e.chomp.split("="); ENV[t[0]] = t[1] if t.size == 2}

while(1) do
  
  data_dir = Pathname.new(ENV["DATA_DIR"])
  tmp_dir = data_dir + 'tmp'
  
  md5s =  Dir.entries(tmp_dir).map{|e| m = e.match(/(\w+)\.tmp/); ((m and m[1]) ? m[1] : nil)}.compact.select{|e| File.exist?(tmp_dir + e + 'output.json')  and !File.exist?(tmp_dir + e + 'gwas_output.json')}.sort{|a, b| File.ctime(tmp_dir + (a + '.tmp')) <=> File.ctime(tmp_dir + (b + '.tmp'))}
  #.sort{|a, b| File.ctime(tmp_dir + a + 'output.json') <=> File.ctime(tmp_dir + b + 'output.json')}# or File.size(tmp_dir + e + 'gwas_output.json') < 80
  
  #    puts md5s
  #    exit
  #    md5s = Dir.entries(tmp_dir).map{|e| m = e.match(/(\w+)\.tmp/); ((m and m[1]) ? m[1] : nil)}.compact.select{|e| File.exist?(tmp_dir + e) and !File.exist?(tmp_dir + e + 'gwas_output.json')}
  
  
  #    md5s.each do |md5|
  if md5s.size > 0
    md5 = md5s.first
    puts md5
    tmp_file = tmp_dir + "#{md5}.tmp"
    output_dir =  tmp_dir + md5
    #   export_mean_file = data_dir + 'export_mean.tsv'
    #   t_header[0] = 'DGRP'
    #   if !File.exist? tmp_file
    #     File.open(tmp_file, 'w') do |f|
    #       f.write(t_header.join("\t") + "\n" )
    #       f.write(content)
    #     end
    #   end
    
    plink_file = data_dir + 'dgrp2'
    cov_file = data_dir + "dgrp.cov.tsv"
    annot_file = data_dir + "dgrp.fb557.annot.txt.gz"
    File.delete(output_dir + "done") if File.exist?(output_dir + "done")
    cmd = "Rscript ./src/lib/running_GWAS_user.R #{tmp_file} #{plink_file} #{cov_file} #{annot_file} #{output_dir} 2 0.2 0.05 1> #{output_dir + "gwas_output.json"} 2> #{output_dir + "gwas_output.err"}"
    puts cmd
    `#{cmd}`
    
    `touch #{output_dir + "done"}`
    
  end
  sleep(1)
  
end


