if defined?(Rails) && Rails.logger.nil?
  Rails.logger = Logger.new(STDOUT)
end
