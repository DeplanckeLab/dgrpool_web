desc '####################### fix_cats'
task fix_cats: :environment do
  puts 'Executing...'

  h_study_cats = {}
  Study.all.each do |s|
    h_study_cats = {}
    s.categories.map{|c| h_study_cats[c.id] = c}
    puts h_study_cats.keys.to_json
    s.categories.delete_all
    h_study_cats.each_key do |cat_id|
      s.categories << h_study_cats[cat_id]
    end
  end
  
end

