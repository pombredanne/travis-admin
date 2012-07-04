require 'travis/admin/controller'
require 'sequel'
require 'redis'

module Travis::Admin
  # Middleware that runs before every controller.
  # * Checks username/password
  # * Serves static files
  # * Connects to Redis and SQL database
  class EnvSelector < Travis::Admin::Controller
    enable :static
    set connection_pool: {}

    use Rack::Auth::Basic do |username, password|
      username == settings.username and password == settings.password
    end

    def uri(addr = nil, absolute = true, add_script_name = true)
      return super unless addr and add_script_name
      super(File.join(env['travis.script_name'], addr), absolute, false)
    end

    before do
      settings.databases.each do |db, config|
        next unless request.path_info.start_with? "/#{db}"

        env.merge! \
          'SCRIPT_NAME'             => request.script_name + "/#{db}",
          'PATH_INFO'               => request.path_info.sub("/#{db}", ''),
          'travis.asset_controller' => self,
          'travis.db_name'          => db,
          'travis.db'               => Sequel.connect(config['db']),
          'travis.redis'            => Redis.connect(url: config['redis'])

        env['travis.script_name'] = request.script_name.dup
        env['travis.path_info']   = request.path_info.dup
      end

      redirect to("/#{settings.databases.keys.first}" + request.fullpath), 307 unless env['travis.db']
    end
  end
end
