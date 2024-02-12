desc '####################### compute_sums'
task compute_sums: :environment do
  puts 'Executing...'


  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  Study.all.each do |study|
    Basic.upd_sums(study)
  end
 
end

