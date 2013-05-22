source 'https://rubygems.org'

group :travis do
  gem 'travis-core',     github: 'travis-ci/travis-core'
  gem 'travis-support',  github: 'travis-ci/travis-support'
  gem 'travis-sidekiqs', github: 'travis-ci/travis-sidekiqs'
  gem 'travis-sso',      github: 'travis-ci/travis-sso'

  gem 'gh', github: 'rkh/gh'
  gem 'pg'
end

group :server do
  gem 'sinatra', github: 'sinatra/sinatra'
  gem 'thin'
  gem 'slim', '~> 1.3'
  gem 'redcarpet'
  gem 'rack-ssl'
end

group :console do
  gem 'pry'
end

group :development do
  gem 'rerun'
end
