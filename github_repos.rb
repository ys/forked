require 'octokit'
require 'date'

class GithubRepos
  attr_reader :repo

  def initialize(repo)
    @repo = repo.gsub(' ', '')
  end

  def original
    current = client.repo(repo)
    if current.fork?
      current = current.parent
    end
    Repo.new(current)
  end

  def popular_forks
    client.forks(repo, sort: 'stargazers').map { |repo| Repo.new(repo) }
  end

  def client
    @client ||= Octokit::Client.new(client_id: ENV['GITHUB_CLIENT_ID'],
                                    client_secret: ENV['GITHUB_CLIENT_SECRET'])
  end
end

class Repo
  attr_reader :octokit_repo

  def initialize(octokit_repo)
    @octokit_repo = octokit_repo
  end

  def score
    stargazers_count + forks_count - open_issues_count
  end

  def pushed_at_score
   if ((Date.today - 30).to_time..(Date.today + 1).to_time).cover? pushed_at
      50
   elsif ((Date.today - 90).to_time..(Date.today - 31).to_time).cover? pushed_at
      25
    else
      0
    end
  end

  def method_missing(name, *args, &block)
    octokit_repo.send(name, *args, &block)
  end
end
