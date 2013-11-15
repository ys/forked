require 'sinatra'
require 'sinatra/json'
require 'octokit'
require 'dotenv'
require 'dalli'
require 'rack-cache'

Dotenv.load

class GithubRepo
  attr_reader :repo

  def initialize(repo)
    @repo = repo.gsub(' ', '')
  end


  def original
    current = client.repo(repo)
    if current.fork?
      current = current.parent
    end
    current
  end

  def popular_forks
    client.forks(repo, sort: 'stargazers')
  end

  def client
    @client ||= Octokit::Client.new(client_id: ENV['GITHUB_CLIENT_ID'],
                                    client_secret: ENV['GITHUB_CLIENT_SECRET'])
  end
end

class App < Sinatra::Base
  if memcache_servers = ENV["MEMCACHEDCLOUD_SERVERS"]
    if ENV["MEMCACHEDCLOUD_USERNAME"]
      memcache_servers = "#{ENV["MEMCACHEDCLOUD_USERNAME"]}:#{ENV["MEMCACHEDCLOUD_PASSWORD"]}@#{memcache_servers}"
    end
    use Rack::Cache,
      verbose: true,
      metastore:   "memcached://#{memcache_servers}",
      entitystore: "memcached://#{memcache_servers}"
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
      original = GithubRepo.new(@repo).original
      forks = GithubRepo.new(original.full_name).popular_forks
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
