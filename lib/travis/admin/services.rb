module Travis
  module Admin
    Services = {}

    service_file = File.expand_path('../services.json', __FILE__)
    services     = JSON.load File.read(service_file)

    services.each do |s|
      Services[s['name']] = {
        title:          String(s["title"]),
        events:         Array(s["supported_events"]),
        default_events: Array(s["events"]),
        schema:         Array(s["schema"])
      }
    end
  end
end