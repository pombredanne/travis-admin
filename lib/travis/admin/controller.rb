require 'rack/ssl'
require 'sinatra/base'
require 'redcarpet'
require 'slim'

require 'travis/sso'
require 'travis/admin/helpers'

module Travis::Admin
  class Controller < Sinatra::Base
    set controllers:     [],             sessions: true,
        static:          false,          title:    nil,
        show_exceptions: :after_handler, ssession_secret: Travis.config.session_secret

    helpers Helpers

    use Rack::SSL if production?
    use Travis::SSO, mode: :session, authorized?: -> u { Travis.config.admins.include? u['login'] }

    use Rack::Auth::Basic do |username, password|
      username == 'travis' and password == Travis.config.password
    end

    def self.prefix
      @prefix ||= name[/[^:]+(?=Controller$)/].split(/(?=[A-Z])/).map { |e| "/#{e.downcase}" }.join
    end

    def self.setup_middleware(builder)
      return super if self < Controller
      builder.use Rack::Static, urls: ["/css", "/img", "/js", "/favicon.ico"], root: settings.public_folder
      controllers.each { |c| builder.map(c.prefix) { run c } }
    end

    def self.inherited(controller)
      controller.set protection: false, session: false, app_file: caller_files.detect { |f| f != app_file }
      controllers << controller unless controllers.include? controller
      super
    end

    def find_template(views, name, engine, &block)
      super(File.join(views, settings.prefix), name, engine, &block)
      super(File.join(views, "shared"),        name, engine, &block)
    end

    before do
      klass, message = session.delete 'flash'
      @flash = slim(:flash, locals: {klass: klass.to_s, message: message.to_s}, layout: false) if klass
    end

    # error GH::TokenInvalid do
    #   halt 500, "GitHub token invalid (or wrong OAuth client config)"
    # end
  end
end
