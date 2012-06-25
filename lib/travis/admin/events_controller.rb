require 'travis/admin/controller'
require 'gh'

module Travis::Admin
  class EventsController < Travis::Admin::Controller
    set prefix: '/events', title: 'Event Monitor'

    get '/' do
      slim :index
    end
  end
end
