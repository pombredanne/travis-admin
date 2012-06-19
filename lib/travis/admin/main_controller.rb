require 'travis/admin/controller'

module Travis::Admin
  class MainController < Travis::Admin::Controller
    set :prefix, '/'

    get '/' do
      redirect to(RepoController)
    end
  end
end
