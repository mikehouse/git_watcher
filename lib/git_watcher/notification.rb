
module GitWatcher
  class Notification
    def self.post_notification(title, date, message)
      `osascript -e 'display notification "#{message}" with title "#{title}" subtitle "#{date}" sound name "Glass.iaff"'`
    end
  end
end

