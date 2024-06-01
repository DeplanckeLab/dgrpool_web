desc '####################### load oma_orthologs'
task load_oma_orthologs: :environment do
  puts 'Executing...'

  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  h_oma_orthologs = {}

  h_genes = {}
  Gene.all.map{|g| h_genes[g.identifier] = g; h_genes[g.name] = g}

  oma_organisms_file_path = data_dir + "oma" + "oma-species.txt"
  oma_ensembl_file_path = data_dir + "oma" + "oma-ensembl.txt.gz"
  oma_uniprot_file_path = data_dir + "oma" + "oma-uniprot.txt.gz"
  oma_groups_file_path = data_dir + "oma" + "oma-groups.txt.gz"
 
# Mapping of OMA species codes to NCBI taxon IDs and scientific names.
# Note: OMA species codes are whenever possible identical to UniProt codes.
# Format: OMA code<tab>OMA Taxon ID<tab>NCBI Taxon ID<tab>GTDB genome accession<tab>Scientific name<tab>Genome source<tab>Version/Release
#ABSGL   4829    4829    n/a     Absidia glauca  EnsemblGenomes  Ensembl Fungi 48; AG_v1
#ACAM1   -644103924      329726  RS_GCF_000018105.1      Acaryochloris marina (strain MBIC 11017)        Genome Reviews  18-MAR-2008 (Rel. 88, Last updated, Version 2)


  header = [:oma_identifier, :oma_tax_id, :tax_id, :gtdb_genome_acc, :name, :genome_source, :version]

  puts "parse #{oma_organisms_file_path}..."

  File.open(oma_organisms_file_path, 'rb') do |f|
    while (l = f.gets) do
      if !l.match(/^\#/)
        t = l.chomp.split("\t")
        h = {}
        header.each_index do |i|
          h[header[i]] = t[i]
        end

        h_organism = {
          :oma_identifier => h[:oma_identifier],
          :tax_id => h[:tax_id],
          :name => h[:name],
          :genome_source => h[:genome_source],
          :version => h[:version]
        }
        
        o = Organism.where(:oma_identifier => h[:oma_identifier]).first
        if !o
          o = Organism.new(h_organism)
          o.save
        else
          o.update(h_organism)
        end
      end
    end
  end
  
  puts "Get OMA identifiers by parsing #{oma_groups_file_path}..." 
  # Orthologous groups from OMA release of All.Jun2023
  # This release has 1251567 groups covering 15258796 proteins from 2851 species
  # Format: group number<tab>Fingerprint<tab>tab-separated list of OMA Entry IDs
  #1       FDRGWTQ HALJB02176      HALHT01804      HALMA01103      HALMD02105      HALUD02830      NATM801193      NATPD01971      HALMT03210      HALVU02175

  h_identifiers = {}
  
  File.open(oma_groups_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here
        if !line.match(/^\#/)
          t = line.chomp.split("\t")

          if line.match(/\tDROME/)
            (2 .. t.size-1).to_a.map{|i| h_identifiers[t[i]]=[[], []]}
          end
          
        end
      end
    end
  end

  puts "Identifiers initialized: " + h_identifiers.keys.size.to_s
  
  puts "Get Ensembl IDs"
  File.open(oma_ensembl_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here                                                                                                                                                     
        if !line.match(/^\#/)
          t = line.chomp.split("\t")
          
          if h_identifiers[t[0]] and t[1].match(/^FBgn/)
           
            h_identifiers[t[0]][0].push t[1]
          end          
        end
      end
    end
  end
  
  puts "Get Uniprot IDs"
  File.open(oma_uniprot_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here
        if !line.match(/^\#/)
          t = line.chomp.split("\t")

          if h_identifiers[t[0]]
            h_identifiers[t[0]][1].push t[1]
          end
        end
      end
    end
  end

  puts "Get genes in DGRPool"
  h_existing_genes = {}
  Gene.all.map{|g| h_existing_genes[g.identifier] = g}
  
  puts "add orthologs"

  #  gene_id int references genes,
  #oma_group_id int,
  #organism_id int references organisms,
  #ensembl_ids text,
  #uniprotkb_ids text,
  
  # Format: group number<tab>Fingerprint<tab>tab-separated list of OMA Entry IDs           
  #1       FDRGWTQ HALJB02176      HALHT01804      HALMA01103      HALMD02105      HALUD02830      NATM801193      NATPD01971      HALMT03210      HALVU02175                 

  File.open(oma_groups_file_path, 'rb') do |file|
    # Use Zlib::GzipReader to read the gzipped file
    Zlib::GzipReader.wrap(file) do |gz|
      # Iterate over each line in the gzipped file
      gz.each_line do |line|
        # Process each line here
        if !line.match(/^\#/)
          
          if line.match(/\tDROME/)
            t = line.chomp.split("\t")

            ids = (2 .. t.size-1).to_a.map{|e| t[e]}
            oma_fly_ids = ids.select{|e| e.match(/^DROME/)}
            other_ids = ids - oma_fly_ids
            organism_tags = other_ids.map{|e| e.first(5)}.uniq
            organisms = Organism.where(:oma_identifier => organism_tags).all
            oma_fly_ids.each do |oma_fly_id|
              if h_identifiers[oma_fly_id]
                h_identifiers[oma_fly_id][0].each do |flybase_id|
                  if gene = h_existing_genes[flybase_id]
                    organisms.each do |organism|
                      filtered_other_ids = other_ids.select{|id| h_identifiers[id] and id.first(5) ==  organism.oma_identifier}
                      ensembl_ids = filtered_other_ids.map{|id| h_identifiers[id][0]}.flatten.uniq
                      uniprot_ids =  filtered_other_ids.map{|id| h_identifiers[id][1]}.flatten.uniq
                      if filtered_other_ids.size > 0 and (ensembl_ids.size >0 or uniprot_ids.size > 0)
                        h_oo = {
                          :gene_id => gene.id, :oma_group_id => t[0], :organism_id => organism.id,
                          :ensembl_ids => ensembl_ids.join(","),
                          :uniprot_ids => uniprot_ids.join(",")
                        }
                        
                        ## add entry
                        oo = OmaOrtholog.where(:gene_id => flybase_id, :oma_group_id => t[0], :organism_id => organism.id).first
                        if ! oo
                        oo = OmaOrtholog.new(h_oo)
                        oo.save
                        else
                          oo.update_attribute(h_oo)
                        end
                      end
                    end
                  end
                end
              end
            end
            
          end
          
        end
      end
    end
  end
  
  
end
