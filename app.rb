require 'sinatra'
require 'sinatra/json'
require 'octokit'
require 'dotenv'
Dotenv.load

class GithubRepo
  attr_reader :repo

  def initialize(repo)
    @repo = repo
  end

  def popular_forks
    client.forks(repo, sort: 'stargazers').map do |fork|
      Fork.new(fork.full_name, fork.stargazers_count, fork.updated_at)
    end
  end

  def client
    @client ||= Octokit::Client.new(client_id: ENV['GITHUB_CLIENT_ID'],
                                    client_secret: ENV['GITHUB_CLIENT_SECRET'])
  end
end

Fork = Struct.new(:repo, :stars, :updated_at) do
  def to_json(opts = {})
    { repo: repo, stars: stars, updated_at: updated_at }.to_json
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
      forks = GithubRepo.new(@repo).popular_forks
      erb :forks, locals: { forks: forks }
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
