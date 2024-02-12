require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dgrpool
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.autoload_paths << "#{Rails.root}/extras"
    config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :delayed_job
    #    config.autoload_paths << Rails.root.join("lib")
    #    config.eager_load_paths << Rails.root.join("lib")

        config.action_mailer.smtp_settings = {
      address:  "mail.epfl.ch",
      #      port:     587,
      port: 25,
      enable_starttls_auto: true
    }

    config.action_mailer.default_url_options = {
      :host => "dgrpool.epfl.ch"
    }

    config.action_mailer.default_options = {
      from: "noreply@epfl.ch"
    }

  end
end
