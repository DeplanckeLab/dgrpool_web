json.extract! study, :id, :created_at, :updated_at
#json.summary_type (st = phenotype.summary_type) ? st.name : nil
json.url study_url(study, format: :json)
