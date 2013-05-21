require 'travis'

Travis.setup
Travis::Database.connect
Travis::Notification.setup
Travis.services = Travis::Services
GH::DefaultStack.options[:ssl] = Travis.config.ssl
Travis::Addons.register

require 'forwardable'

module Travis
  module Admin
    require 'travis/admin/controller'
    require 'travis/admin/main_controller'
    require 'travis/admin/repo_controller'
    require 'travis/admin/gh_controller'
    #require 'travis/admin/events_controller'

    extend SingleForwardable
    def_single_delegators Controller, :call, :settings, :new, :configure
  end
end
