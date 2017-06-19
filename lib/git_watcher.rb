
require 'git_watcher/file_manager'

module GitWatcher

  class Main

    def self.args(args)
      if args.empty?
        help
      end

      case args.first
        when 'update'
          update
        when 'add'
          add(args[1], args[2])
        when 'remove'
          remove(args[1], args[2])
        when 'cron'
          cron(args[1])
        when 'show'
          show
        when '-h', '--help'
          help
        else
          puts "There is no such command #{args.first}"
          help
      end
    end

    private

    def self.update
      Git.check_remote
    end

    # @param [Object] value

    def self.cron(value)
      case value
        when 'enable'
          set_cron(3)
        when 'disable'
          disable_cron
        when 'list'
          cron_list
        else
          set_cron(value)
      end
    end

    def self.cron_list
      puts `crontab -l`
    end

    def self.disable_cron
      Dir.chdir(FileManager.root)
      `whenever --clear-crontab`
    end

    # @param [Int] value

    def self.set_cron(value)
      root = File.join(File.expand_path(File.dirname(__FILE__)), '/config/')
      file = Dir.glob(File.join(root, '*.rb'))
          .select { |e| e.end_with?("#{value}_schedule.rb") }
          .first

      unless file
        file = File.join(root, '3_schedule.rb')
      end

      config_folder = File.join(FileManager.root, 'config')
      unless File.directory?(config_folder)
        Dir.mkdir(config_folder)
      end

      main_config = File.join(config_folder, 'schedule.rb')

      if File.exist?(main_config)
        disable_cron
      end

      File.open(main_config, 'w') do |f|
        f << File.read(file)
      end

      Dir.chdir(FileManager.root)

      `whenever`
      `whenever --update-crontab`
    end

    # @param [String] repo
    # @param [String] branch

    def self.add(repo, branch)
      if repo && branch
        GitWatcher::FileManager.add_repository(repo, branch)
      else
        puts 'must specify git repository url' unless repo
        puts 'must specify branch name' unless branch
        exit
      end
    end

    # @param [String] repo
    # @param [String] branch

    def self.remove(repo, branch)
      if branch
        GitWatcher::FileManager.remove_branch(repo, branch)
      else
        GitWatcher::FileManager.remove_repository(repo)
      end
    end

    def self.show
      if File.exist?(FileManager.configuration_file)
        puts File.read(FileManager.configuration_file)
      end
    end

    def self.help
      help = """
        commands:

          add git_url branch_name - add branch to tracking system
          remove git_url - remove tracking all branches for given repository
          remove git_url branch_name - remove tracking specific branch for given repository
          show - show all repositories and its branches
          cron 5 - set to run script every given interval (values can be 3, 5, 10, 30 and 60 minutes)
          cron enable - enable cron schedule by default value (3 minutes is default)
          cron disable - disable script's schedule
          cron list - cron's schedule
      """
      puts help
      exit
    end

  end

end
