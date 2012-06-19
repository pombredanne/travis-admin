require 'sinatra/base'
require 'travis/admin'
require 'travis/admin/helpers'
require 'slim'

module Travis::Admin
  # Superclass for all controllers. Can be used as Rack endpoint.
  class Controller < Sinatra::Base
    helpers Helpers
    set controllers: [], builder: Rack::Builder.new
    disable :static, :title

    require 'travis/admin/env_selector'
    builder.use EnvSelector

    def self.prefix=(value)
      controller = self
      define_singleton_method(:prefix) { value }
      builder.map(value) { run controller }
    end

    def self.new(*)
      self == Controller ? builder.to_app : super
    end

    def self.inherited(subclass)
      controllers << subclass unless controllers.include? subclass
      subclass.set :app_file, caller_files.detect { |f| f != app_file }
      super
    end

    def find_template(views, name, engine, &block)
      super(File.join(views, settings.prefix), name, engine, &block)
      super(File.join(views, "shared"),        name, engine, &block)
    end

    def middleware?
      @app
    end

    before do
      next if middleware?
      klass, message = session.delete 'flash'
      @flash = slim(:flash, locals: {klass: klass.to_s, message: message.to_s}, layout: false) if klass
    end
  end
end
