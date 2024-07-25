namespace :custom_sunspot do
  desc "Custom Reindex Sunspot"
  task reindex: :environment do
    begin
      # Ensure logger is set
      Rails.logger ||= ActiveSupport::Logger.new(STDOUT)
      logger = Rails.logger

      # Debugging: Check if logger is nil
      if logger.nil?
        Rails.logger = ActiveSupport::Logger.new(STDOUT)
        logger = Rails.logger
        Rails.logger.info("[#{Time.now}] Logger was nil, reinitialized")
      else
        Rails.logger.info("[#{Time.now}] Logger is already initialized")
      end

      # Log the start of indexing
      logger.info("[#{Time.now}] Start Indexing")

      # Invoke the original task
      Rake::Task['sunspot:reindex'].invoke(500, 'Gene')
    rescue => e
      logger.error("Error during reindexing: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      raise e
    end
  end
end
