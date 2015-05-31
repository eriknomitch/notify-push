require "dotenv"
require "json"
require "shellwords"

Dotenv.load

# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

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
  # ----------------------------------------------
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
  # ----------------------------------------------
  # ----------------------------------------------
  module Receiver
    def self.start(argv)
      require "pusher-client"

      options = { secure: true }
      socket = PusherClient::Socket.new(ENV["PUSHER_KEY"], options)

      # Subscribe to two channels
      socket.subscribe(CHANNEL_NAME)
      #socket.subscribe('channel2')

      # Subscribe to presence channel
      #socket.subscribe('presence-channel3', USER_ID)

      # Subscribe to private channel
      #socket.subscribe('private-channel4', USER_ID)

      # Subscribe to presence channel with custom data (user_id is mandatory)
      #socket.subscribe('presence-channel5', :user_id => USER_ID, :user_name => 'john')

      # Bind to a global event (can occur on either channel1 or channel2)
      #socket.bind('notification') do |data|
      #end

      # Bind to a channel event (can only occur on channel1)
      socket[CHANNEL_NAME].bind('notification') do |data|
        data = JSON.parse(data)

        message = data["message"]
        title   = data["title"].nil? ? "notify-push" : data["title"]
        subtitle   = data["subtitle"].nil? ? false : data["subtitle"]

        args = ["-title", title, "-message", message]

        if subtitle
          args.concat ["-subtitle", subtitle]
        end

        system "terminal-notifier", *args

        puts "------"
        puts data
      end

      socket.connect

      0
    end
  end
end
