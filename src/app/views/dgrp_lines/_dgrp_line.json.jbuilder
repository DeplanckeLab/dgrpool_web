json.extract! dgrp_line, :id, :name, :nber_studies, :nber_phenotypes, :fbsn, :bloomington_id, :created_at, :updated_at
#dgrp_status_id int references dgrp_statuses,                                      
json.dgrp_status (ds = dgrp_line.dgrp_status) ? ds.label : nil
json.url dgrp_line_url(dgrp_line, format: :json)
