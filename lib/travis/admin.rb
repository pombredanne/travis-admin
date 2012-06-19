require 'forwardable'

module Travis
  module Admin
    require 'travis/admin/gh_controller'
    require 'travis/admin/main_controller'
    require 'travis/admin/repo_controller'

    extend SingleForwardable
    def_single_delegators Controller, :call, :settings, :new, :configure
  end
end
