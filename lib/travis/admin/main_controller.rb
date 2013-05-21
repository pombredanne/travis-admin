require 'travis/admin/controller'

module Travis::Admin
  class MainController < Controller
    set prefix: '/'

    get '/' do
      redirect to(RepoController)
    end
  end
end
