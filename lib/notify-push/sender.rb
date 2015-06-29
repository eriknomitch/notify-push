# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # MODULE->SENDER -------------------------------
  # ----------------------------------------------
  module Sender

    class << self
      delegate :configuration, to: :parent
    end

    def self.send_notification()

      ARGV.shift

      # The only thing we require is a message.
      # The others will be nil if not supplied.
      raise "No message supplied." if ARGV[0].blank?
      
      ::NotifyPush.acting_as = self
      
      notification = {
        message:  ARGV[0],
        title:    ARGV[1],
        subtitle: ARGV[2]
      }

      puts "Sending notification (backgrounded) with data:"
      puts "  message-> #{notification[:message]}"
      puts "    title-> #{notification[:title]}"
      puts " subtitle-> #{notification[:subtitle]}"
     
      # Daemonize now.
      Process.daemon true
      
      require "pusher"
      
      # Strip the nil key/value pairs out so we don't have to 
      # worry about them on the Receiver end.
      notification.delete_if {|key, value| value.blank?}

      # Connect to Pusher and trigger the notification
      Pusher.url = "http://#{configuration.pusher.key}:#{configuration.pusher.secret}@api.pusherapp.com/apps/#{configuration.pusher.app_id}"

      Pusher[CHANNEL_NAME].trigger("notification", notification)

      0
    end

  end

end
