require "dotenv"
require "json"
require "shellwords"

Dotenv.load

# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  CHANNEL_NAME = "notify-push"
  
  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  def self.start(argv)
    if ["--receiver", "-r"].member? argv[0]
      return NotifyPush::Receiver.start(argv)
    end

    NotifyPush::Sender.start(argv)
  end

  # ----------------------------------------------
  # MODULE->SENDER -------------------------------
  # ----------------------------------------------
  module Sender
    def self.start(argv)
      require "pusher"

      raise "No message supplied." if argv.length == 0

      message = argv[0]
      title   = argv[1]

      Pusher.url = "http://#{ENV["PUSHER_KEY"]}:#{ENV["PUSHER_SECRET"]}@api.pusherapp.com/apps/#{ENV["PUSHER_APP_ID"]}"

      Pusher[CHANNEL_NAME].trigger('notification', {
        message: message,
        title: title
      })

      0
    end
  end

  # ----------------------------------------------
  # MODULE->RECEIVER -----------------------------
  # ----------------------------------------------
  module Receiver
    def self.start(argv)
      require "pusher-client"

      options = { secure: true }
      socket = PusherClient::Socket.new(ENV["PUSHER_KEY"], options)

      # Subscribe to main channel
      socket.subscribe(CHANNEL_NAME)

      # Bind to the main channel event 
      socket[CHANNEL_NAME].bind('notification') do |data|

        begin
          data = JSON.parse(data)

          message = data["message"]
          title   = data["title"].nil? ? "notify-push" : data["title"]
          subtitle   = data["subtitle"].nil? ? false : data["subtitle"]

          args = ["-title", title, "-message", message]

          if subtitle
            args.concat ["-subtitle", subtitle]
          end

          system "terminal-notifier", *args

        rescue => exception
          puts "Warning: Failed to process notification."
          puts exception
        ensure
          puts data
          puts "------"
        end
      end

      # Bind to the error event
      socket.bind("pusher:error") do |data|
        puts "Warning: Pusher Error"
        puts data
        upts "----"
      end

      # Connect
      socket.connect

      0
    end


  end
end
