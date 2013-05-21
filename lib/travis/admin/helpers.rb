require 'travis/admin'
require 'cgi'

module Travis::Admin
  module Helpers
    def h(string)
      CGI.escapeHTML(string)
    end

    def active?(controller)
      prefix = controller.prefix.split('/')
      path   = request.path.split('/')
      prefix.zip(path).all? { |a,b| a == b }
    end

    # Allows things like `redirect to(RepoController)`.
    def uri(addr, absolute = true, add_script_name = true)
      return super unless addr.respond_to? :prefix
      uri(addr.prefix, absolute, false)
    end

    alias url uri
    alias to uri

    def as_user(name, &block)
      user   = User.find_by_login!(name)
      @token = user.github_oauth_token
      Travis::Github.authenticated(user, &block)
    end

    def with_token(token, &block)
      @token = token
      GH.with(token: token, &block)
    end

    def flash(klass, message = nil)
      klass, message = :info, klass unless message
      session['flash'] = [klass, message]
      redirect(params['return_to'] || back)
    end
  end
end
