require "json"
require "shellwords"
require "yaml"
require "recursive-open-struct"
require "active_support/dependencies" # For mattr_accessor

# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush
  
  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  mattr_accessor :configuration

  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  CHANNEL_NAME = "notify-push"
  
  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  def self.initialize_configuration()
    begin
      self.configuration = RecursiveOpenStruct.new(YAML.load_file("#{ENV["HOME"]}/.notify-pushrc"))
    rescue => exception
      puts "fatal: Could not initialize configuration file."
      puts exception
    end
  end
  
  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  def self.start(argv)
    initialize_configuration

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

      Pusher.url = "http://#{::NotifyPush.configuration.pusher.key}:#{::NotifyPush.configuration.pusher.secret}@api.pusherapp.com/apps/#{::NotifyPush.configuration.pusher.app_id}"

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
      socket = PusherClient::Socket.new(::NotifyPush.configuration.pusher.key, options)

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
