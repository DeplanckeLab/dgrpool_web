desc '####################### load_var_types'
task load_var_types: :environment do
  puts 'Executing...'

  
  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  var_types_file = data_dir + 'var_types.tab'
  puts "Load snps..."

  h_impact = {
    'HIGH' => 'danger',
    'MODERATE' => 'warning',
    'LOW' => 'secondary',
    'MODIFIER' => 'info'
  }
  
  File.open(var_types_file, 'r') do |f|
    while(l = f.gets) do
      puts l
      t = l.split("\t")
      puts t[1]
      puts t[2]
      puts t[3]

      h={
        :name => t[1].strip,
        :description => t[2].strip,
        :impact => t[3].strip,
        :impact_class => h_impact[t[3].strip]
      }

      var_type = VarType.where(:name => t[1]).first
      if !var_type
        var_type = VarType.new(h)
        var_type.save
      else
        var_type.update(h)
      end
    end
  end
  
end

