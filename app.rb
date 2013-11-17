require 'sinatra'
require 'sinatra/json'
require 'dotenv'
require 'cache'
require 'newrelic_rpm'
require 'github_repos'

Dotenv.load


class App < Sinatra::Base
  include Cache

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
