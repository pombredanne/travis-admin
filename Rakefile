require 'bundler/setup'
require './config/environment'

task :crowd_sync do
  dump_file = File.expand_path('crowd.dump', Travis::Admin.settings.root)
  sh "heroku pgbackups:capture --expire --app travis-crowd-production"
  sh "curl -o '#{dump_file}' `heroku pgbackups:url --app travis-crowd-production`"
  sh "pg_restore --verbose --clean --no-acl --no-owner -d travis-crowd '#{dump_file}'"
end
