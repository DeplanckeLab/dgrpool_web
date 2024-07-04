json.extract! phenotype, :id, :study_id, :name, :is_summary, :is_continuous, :is_numeric, :created_at, :updated_at
json.summary_type (st = phenotype.summary_type) ? st.name : nil
json.unit (u = phenotype.unit) ? u.label : nil
json.original_data @h_original_data
json.summary_data @h_summary_data if phenotype.is_summary == false
json.url phenotype_url(phenotype, format: :json)
