require 'git_watcher/file_manager'
require 'git_watcher/notification'

module GitWatcher

  class Git

    class Commit
      attr_accessor :title, :date, :message, :hash
    end

    # @param [String] repo
    # @param [String] branch
    # @param [Int] commits - how many last commits to use

    def initialize(repo, branch, commits)
      @repo = repo
      @branch = branch
      @commits = commits ? commits : 3
    end

    def exists_locally?
      File.directory?(git_path)
    end

    # @return [Array<Commit>]

    # @param [Int] count

    def last_commits(count)
      if count < 1
        count = 1
      end

      switch_to_repository

      hashes = `git log -#{count} | grep commit`.split(' ').select { |e| !e.include?('commit') }
      exit_on_cmd_error

      repo_name = @repo.split('/').last.split('.').first

      hashes.collect do |hash|
        commit = Commit.new

        commit.title = repo_name + '/' + @branch + '/' + `git log #{hash} -1 | grep Author:`['Author:'.length..-1].strip
        commit.date = `git log #{hash} -1 | grep Date:`['Date:'.length..-1].strip

        commit_full = `git log #{hash} -1`
        length_to_crop = commit_full.index(commit.date) + commit.date.length + 1

        commit.message = commit_full[length_to_crop..-1].strip
        commit.hash = hash

        commit
      end
    end

    def self.check_remote
      configuration = FileManager.configuration
      if configuration.empty?
        puts 'There is no any repository to run with'
        exit
      end
      configuration.each do |git, hash|
        branches = hash['branch']
        if branches
          branches.each do |branch, _|
            Git.new(git, branch, nil).run_repository
          end
        else
          puts "There is no branches for repository #{git} to run with"
        end
      end
    end

    # @param [String] repo
    # @param [String] branch

    def self.validate_repository(repo, branch)
      res = `git ls-remote #{repo}`
      unless $?.exitstatus == 0
        puts res
        exit
      end

      res = `git ls-remote --heads #{repo}`
                .split("\n")
                .select { |e| e.end_with?("refs/heads/#{branch}") }
                .first

      unless $?.exitstatus == 0
        puts res
        exit
      end

      unless res
        puts "couldn't find branch #{branch} for remote #{repo}"
        exit
      end
    end

    def run_repository
      unless exists_locally?
        @commits = 1
      end

      commits = last_commits(@commits)
      last_commit = FileManager.last_checked_commit(@repo, @branch)
      commits_to_notify = []

      if last_commit
        idx = commits.index { |e| e.hash == last_commit }
        if idx
          if idx == 0
            puts "There are no new commits at #{@repo} within #{@branch} branch"
            return
          else
            commits_to_notify = commits.take(idx)
          end
        else
          commits_to_notify = commits
        end
      else
        commits_to_notify << commits.first
      end

      FileManager.add_last_commit(@repo, @branch, commits_to_notify.first.hash)

      commits_to_notify.reverse.each do |commit|
        Notification.post_notification(commit.title, commit.date, commit.message)
        sleep(3)
      end
    end

    def exit_on_cmd_error
      unless $?.exitstatus == 0
        puts "exit status code #{$?.exitstatus}"
        exit
      end
    end

    def project_path
      File.join(FileManager::root, @repo.split('/').last.split('.').first)
    end

    def git_path
      project = File.join(FileManager::root, @repo.split('/').last.split('.').first)
      File.join(project, '.git')
    end

    def switch_to_repository
      unless File.directory?(git_path)
        Dir.chdir(FileManager::root)
        git_clone
      end

      Dir.chdir(project_path)
      `git stash && git pull origin #{@branch}`
      exit_on_cmd_error
    end

    def git_clone
      `git clone -b #{@branch} #{@repo}`
      exit_on_cmd_error
    end

  end

end
