class SnpGene < ApplicationRecord

  belongs_to :gene
  belongs_to :snp
  belongs_to :var_type
  
  searchable do
    text :gene_name do
      gene.name
    end
    string :gene_name_order do
      gene.name
    end
    text :snp_identifier do
      snp.identifier
    end
    integer :var_type_id
    text :impact do
      var_type.impact
    end
    boolean :affects_tf_binding_site
    boolean :affects_regulatory_region
  end
end
