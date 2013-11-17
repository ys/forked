require 'sinatra'
require 'sinatra/json'
require 'dotenv'
require 'newrelic_rpm'
require 'github_repos'
require 'dalli'
require 'rack-cache'

Dotenv.load


class App < Sinatra::Base
  if ENV["MEMCACHEDCLOUD_SERVERS"]
    cache = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(","),
                              {:username => ENV["MEMCACHEDCLOUD_USERNAME"],
                               :password => ENV["MEMCACHEDCLOUD_PASSWORD"],
                               :failover => true,
                               :socket_timeout => 1.5,
                               :socket_failure_delay => 0.2
    })
    use Rack::Cache,
      verbose: true,
      metastore:   cache,
      entitystore: cache
  end

  configure do
    set :show_exceptions, false
  end

  get '/' do
    cache_control :public, max_age: 3600  # 60 mins.
    erb :home
  end

  get '/:username/:repo' do
    cache_control :public, max_age: 1800  # 30 mins.
    begin
      @repo = "#{params[:username]}/#{params[:repo]}"
      original = GithubRepos.new(@repo).original
      forks = GithubRepos.new(original.full_name).popular_forks
      erb :forks, locals: { original: original, forks: forks }
    rescue Octokit::NotFound
      erb :err400
    end
  end

  not_found do
    @repo = request.path
    erb :err400
  end

  error do
    erb :err500
  end
end
