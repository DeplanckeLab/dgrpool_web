#Rails.application.config.after_initialize do
  Rails.application.config.session_store :active_record_store, :key => '_dgrpool_session', :secure => true
#end
