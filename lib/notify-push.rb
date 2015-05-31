require "dotenv"
require "json"

Dotenv.load

module NotifyPush

  CHANNEL_NAME = "notify-push"

  def self.start_sender(argv)
    require "pusher"

    raise "No message supplied." if argv.length == 0

    message = argv[0]

    Pusher.url = "http://#{ENV["PUSHER_KEY"]}:#{ENV["PUSHER_SECRET"]}@api.pusherapp.com/apps/#{ENV["PUSHER_APP_ID"]}"

    Pusher[CHANNEL_NAME].trigger('notification', {
      message: message
    })
  end

  module Receiver
    def self.start
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

        title = "notify-push"

        system "terminal-notifier -title #{title} -message \"#{data["message"]}\""

        puts "------"
        puts data
        puts message
      end

      socket.connect
    end
  end
end
