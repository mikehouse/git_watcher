require 'git_watcher/file_manager'

set :output, File.join(GitWatcher::FileManager.root, 'cron_log.log')

job_type :update, 'git_watcher :task'

every 3.minutes do
  update 'update'
end