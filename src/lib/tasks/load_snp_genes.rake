desc '####################### load_snp_genes'
task load_snp_genes: :environment do
  puts 'Executing...'

  ## DGRP3 (4.7M snps): the previous version kept every SnpGene object in memory and saved them one by one.
  ## It crashed after 2.7M rows (Ruby heap > vm.max_map_count) after 14h, mostly spent indexing each row in Solr
  ## (SnpGene is 'searchable' but its index is never queried). Now:
  ##  - only the (snp_id, gene_id) pairs of the current page are loaded, to skip existing rows;
  ##  - new rows are written with insert_all (one query per page, no Solr indexing);
  ##  - the run resumes at the page of the last snp_id already in snp_genes (earlier pages are complete).
  ## Same rows as before: one per (snp, gene), with the var_type of the first transcript annotation that names the gene.

  puts "loading existing objects..."
  h_var_types = {}
  VarType.all.map{|e| h_var_types[e.name] = e}
  h_genes = {}
  Gene.all.map{|g| h_genes[g.name] = g}

  size_page = 1000
  min_id = Snp.minimum(:id)
  last_id = Snp.maximum(:id)
  abort "snps table is empty" if !min_id
  resume_id = SnpGene.maximum(:snp_id)
  first_page = ((resume_id || min_id) - 1) / size_page
  last_page = (last_id - 1) / size_page
  puts (resume_id) ? "continuing from snp_id #{resume_id}..." : "start parsing..."

  nb_created = 0
  (first_page .. last_page).each do |page|
    snps = Snp.where("id > ? and id <= ?", page * size_page, (page + 1) * size_page).order(:id).pluck(:id, :annots_json)
    next if snps.empty?
    existing = {}
    SnpGene.where(:snp_id => snps.map(&:first)).pluck(:snp_id, :gene_id).each{|k| existing[k] = true}
    rows = []
    snps.each do |snp_id, annots_json|
      h_snps = Basic.safe_parse_json(annots_json, {})
      next if !h_snps['transcript_annot']
      bsa = h_snps['binding_site_annot'] || {}
      h_snps['transcript_annot'].each_key do |k|
        var_type = h_var_types[k]
        h_snps['transcript_annot'][k].each do |gene_name|
          next if gene_name[0] == ''
          gene = h_genes[gene_name[0]]
          if !gene
            gene = Gene.new({:name => gene_name[0]})
            gene.save
            h_genes[gene_name[0]] = gene
          end
          next if !var_type or !gene.id or existing[[snp_id, gene.id]]
          existing[[snp_id, gene.id]] = true
          rows.push({
            :snp_id => snp_id,
            :gene_id => gene.id,
            :var_type_id => var_type.id,
            :affects_regulatory_region => (bsa['regulatory_region']) ? true : false,
            :affects_tf_binding_site => (bsa['TF_binding_site']) ? true : false
          })
        end
      end
    end
    if rows.size > 0
      SnpGene.insert_all(rows)
      nb_created += rows.size
    end
    puts "page #{page}/#{last_page}: #{nb_created} snp_genes created" if page % 100 == 0
  end
  puts "Done: #{nb_created} snp_genes created, #{SnpGene.count} in total"

end
