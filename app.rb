require 'sinatra'
require 'sinatra/json'
require 'octokit'
require 'dotenv'
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
  configure do
    set :show_exceptions, false
  end
  get '/' do
    erb :home
  end
  get '/:username/:repo' do
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
