desc '####################### get flybase strains'
task get_flybase_strains: :environment do
  puts 'Executing...'
  
  time = Time.now
  
  flybase_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'flybase' + 'FBsn'

  Dir.entries(flybase_dir).select{|f| !File.directory?(flybase_dir + f)}.each do |f|
    puts "Exploring #{flybase_dir + f}..."
    fbsn = nil
    if m = f.match(/(FBsn\d+)/)
      fbsn = m[1]
    end
    data = File.read(flybase_dir + f).split(/[\r\n]+/)
    
    dgrp = []
    data.each do |l|#      puts "-" + l + "-"
      if l.match(/<strainprop>/)
        puts "bla"
        break
      end
 #     puts "-" + l + "-"
      if m = l.match(/<name>DGRP-(\d+)<\/name>/)
  #      puts "add #{m[1]}!"
        dgrp.push m[1]
      end
    
    end

    if dgrp.size == 1
      n = dgrp.first.to_s
      name = "DGRP_" + ("0" * (3 - n.size)) + n
      puts "Association to " + name
      dgrp_line = DgrpLine.where(:name => name).first
      dgrp_line.update(:fbsn => fbsn)
    elsif dgrp.size > 1
      puts "Ambiguity: " + dgrp.to_json
    end
    
  end
end

