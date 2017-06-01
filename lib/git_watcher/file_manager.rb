
require 'json'
require 'git_watcher/git'

module GitWatcher

  class FileManager

    # @return [String]

    def self.root
      root = File.join(Dir.home, '/Library/Application Support/com.git.watcher/')
      unless File.directory?(root)
        Dir.mkdir(root)
      end
      root
    end

    # @param [String] repo
    # @param [String] branch

    def self.add_repository(repo, branch)
      GitWatcher::Git.validate_repository(repo, branch)

      json = configuration
      repository = json[repo]
      if repository
        branches = repository['branch']
        if branches
          branches.store(branch, {})
        else
          repository['branch'] = {branch => {}}
        end
      else
        repository = {'branch' => {branch => {}}}
      end

      json[repo] = repository

      write_configuration(json)
    end

    # @param [String] repo

    def self.remove_repository(repo)
      json = configuration
      if json.delete(repo)
        write_configuration(json)
        repo_dir = File.join(FileManager.root, repo.split('/').last.split('.').first)
        if File.directory?(repo_dir)
          `rm -fr '#{repo_dir}'`
        end
      else
        puts "There is no such repository #{repo} to work with"
      end
    end

    # @param [String] repo
    # @param [String] branch

    def self.remove_branch(repo, branch)
      json = configuration
      repository = json[repo]
      if repository
        branches = repository['branch']
        if branches
          if branches.include?(branch)
            branches.delete(branch)
            repository['branch'] = branches
          else
            puts "There is no such branch #{branch} within repository #{repo} to delete for"
            exit
          end
        else
          puts "There is no such branch #{branch} within repository #{repo} to delete for"
          exit
        end
      else
        puts "There is no such repository #{repo} to work with"
        exit
      end
      json[repo] = repository
      write_configuration(json)
    end

    # @param [String] repo
    # @param [String] branch

    def self.last_checked_commit(repo, branch)
      json = configuration
      repository = json[repo]
      if repository
        branches = repository['branch']
        if branches
          brn = branches[branch]
          if brn
            return brn['commit']
          end
        end
      end
      return nil
    end

    # @param [String] repo
    # @param [String] branch
    # @param [String] commit

    def self.add_last_commit(repo, branch, commit)
      json = configuration
      repository = json[repo]
      if repository
        branches = repository['branch']
        if branches
          brn = branches[branch]
          if brn
            brn['commit'] = commit
          else
            branches[branch] = {'commit' => commit}
          end
        end
      end

      write_configuration(json)
    end

    # @return [String]

    def self.configuration_file
      File.join(root, 'configuration.json')
    end

    # @return [Hash]

    def self.configuration
      if File.exist?(configuration_file)
        JSON.parse(File.read(configuration_file))
      else
        {}
      end
    end

    private

    # @param [Hash] configuration

    def self.write_configuration(configuration)
      File.open(configuration_file, 'w') do |file|
        file << JSON.pretty_generate(configuration)
      end
    end

  end

end
