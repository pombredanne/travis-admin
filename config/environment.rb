$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'travis/admin'
require 'json'
require 'yaml'

Travis::Admin.configure do |config|
  config.enable :sessions, :show_exceptions
  config.set services: {}, root: File.expand_path('../..', __FILE__)

  settings_file = File.expand_path("../#{config.environment}/settings.yml", __FILE__)
  config.set YAML.load_file(settings_file)

  service_file = File.expand_path('../services.json', __FILE__)
  services     = JSON.load File.read(service_file)

  services.each do |s|
    config.services[s['name']] = {
      title:          String(s["title"]),
      events:         Array(s["supported_events"]),
      default_events: Array(s["events"]),
      schema:         Array(s["schema"])
    }
  end

  db_file = File.expand_path("../#{config.environment}/database.yml", __FILE__)
  config.set databases: YAML.load_file(db_file)
  config.set crowd_db: config.databases.delete('crowd')['db']

  config.configure :production do |production_config|
    require 'rack/ssl'
    production_config.use Rack::SSL
  end
end
