desc '####################### load studies'
task load_studies: :environment do
  puts 'Executing...'


  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  all = 0
  found = 0

  list_dois = []


  ## initial load from file
  #status_id = 2
  #File.open(data_dir + "dois.txt") do |f|
  #  while(l = f.gets) do
  #    list_dois.push(l.chomp.strip)
  #  end
  #end

  ## load from db last submitted dois

#  list_dois = Study.joins(:status).where(:status => {:name => 'submitted'}).map{|s| s.doi}
  #  list_dois = Study.all.map{|s| s.doi}.select{|doi| doi == '10.1128/AEM.03301-15'}
#  list_dois = Study.all.map{|s| s.doi}
  list_dois = Study.all.map{|s| s.doi and s.status_id == 1 and s.first_author == nil}
  status_id = 1
  
  list_dois.each do |doi|
    
    if doi.size > 0
      h = CustomFetch.doi_info(doi)
      #        puts h.to_json
      all+=1
      if h.keys.size > 0 and h[:first_author] != nil and h[:title]
        h[:status_id] = status_id
        
        found+=1
        s = Study.where(:doi => doi).first
        if !s
          h.delete(:title)
          s = Study.new(h)
          s.save
        else
          puts "Update study..."
          #            h[:key] = Basic.create_key(Study, 6) if !s.key
          s.update(h)
        end
      else
        puts "#{doi}: Not found"
      end
      
    end
  end
  puts all
  puts found
  
end
