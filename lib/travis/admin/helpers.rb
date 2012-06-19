require 'travis/admin'

module Travis::Admin
  module Helpers
    def db
      env['travis.db']
    end

    def db_name
      env['travis.db_name']
    end

    def redis
      env['travis.redis']
    end

    def active?(controller)
      prefix = controller.prefix.split('/')
      path   = env['travis.path_info'].split('/')
      prefix.zip(path).all? { |a,b| a == b }
    end

    # Allows things like `redirect to(RepoController)`.
    def uri(addr, *args)
      return super unless addr.respond_to? :prefix
      env['travis.asset_controller'].uri(addr.prefix, *args)
    end

    alias url uri
    alias to uri

    def gh
      @gh ||= GH::DefaultStack.build
    end

    def with_token(token)
      flash :error, '**Could not access GitHub**:  We do not have the GitHub token.' unless token
      @gh = GH::DefaultStack.build(token: @token = token)
    end

    def as_user(login)
      result = db[:users].first(login: login)
      flash :error, '**Could not access GitHub**: User not known to Travis!' unless result
      with_token result[:github_oauth_token]
    rescue Sequel::DatabaseDisconnectError
      retry
    end

    def flash(klass, message = nil)
      klass, message = :info, klass unless message
      session['flash'] = [klass, message]
      redirect(params['return_to'] || back)
    end
  end
end
