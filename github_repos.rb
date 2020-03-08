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

module Node
  def children
    @children ||= []
  end

  def leaf?
    children.empty?
  end

  def leaf_with_hidden?
    children.empty?
  end


  def <<(child)
    children << child
  end

  def inspect(indent = '')
    indent_step = '    '
    "#{indent}#{full_name}" +
      if leaf?
        forks_count > 0 ? "(#{forks_count})\n#{indent}#{indent_step}...\n" : "\n"
      else
        " (#{forks_count})\n" + children.map{|child| child.inspect(indent + indent_step)}.join
      end
  end

end


class Repo
  include Node
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


module Network

  DEPTH_LIMIT = 2

  class << self

    def build(repo, depth_limit = DEPTH_LIMIT)
      build_network_for_repo(repo.original, repo.popular_forks, depth_limit)
    end

    def build_network_for_repo(root_repo, children, depth)
      unless depth == 0
        children.each do |repo|

          root_repo <<  if repo.forks_count == 0
            repo
          else
            this_repo_babies = GithubRepos.new(repo.full_name).popular_forks
            build_network_for_repo(repo, this_repo_babies, depth - 1)
          end

        end
      end
      root_repo
    end

  end
end
