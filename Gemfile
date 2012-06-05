source :rubygems
ruby '1.9.3' if RUBY_ENGINE == 'ruby'

gem 'sinatra',          github: 'sinatra',                 branch: 'master'
gem 'sinatra-contrib',  github: 'sinatra/sinatra-contrib', branch: 'master'
gem 'gh',               github: 'rkh/gh',                  branch: 'master'

gem 'addressable'
gem 'sequel'
gem 'pg'

gem 'rack-ssl'

gem 'slim'

platform :ruby do
  gem 'rdiscount'
  gem 'puma', github: 'puma', branch: 'master'
end

platform :jruby do
  gem 'kramdown'
  gem 'trinidad'
  gem 'jdbc-postgres'
end

