require "json"
require "shellwords"
require "yaml"
require "recursive-open-struct"
require "active_support/dependencies" # For mattr_accessor
require 'active_support/core_ext/hash/reverse_merge'
require 'daemons'

#Daemons.daemonize

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
  CONFIGURATION_FILE_PATH = "#{ENV["HOME"]}/.notify-pushrc"
  
  # ----------------------------------------------
  # ----------------------------------------------
  # ----------------------------------------------
  def self.initialize_configuration()
    unless File.exist? CONFIGURATION_FILE_PATH
      raise "Configuration file does not exist at '#{CONFIGURATION_FILE_PATH}'."
    end

    self.configuration = RecursiveOpenStruct.new(YAML.load_file(CONFIGURATION_FILE_PATH))
  end
  
  # ----------------------------------------------
  # MAIN -----------------------------------------
  # ----------------------------------------------
  def self.main(argv)
    begin
      initialize_configuration

      if ["--receiver", "-r"].member? argv[0]
        return NotifyPush::Receiver.start(argv)
      end

      NotifyPush::Sender.start(argv)
    rescue => exception
      puts "fatal: #{exception.to_s}"
      exit 1
    end
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
    def self.pid_lock
      require "pidfile"

      PidFile.new
    end

    def self.ensure_dependencies
      system "command -v terminal-notifier >/dev/null 2>&1" or raise "'terminal-notifier' cannot be found."
    end

    def self.ensure_compatibility
      `uname`.chomp("\n") == "Darwin" or "The notify-push receiver only supports OS X."
    end

    def self.start(argv)

      ensure_compatibility
      ensure_dependencies
      pid_lock

      require "pusher-client"

      socket = PusherClient::Socket.new ::NotifyPush.configuration.pusher.key, {
        secure: true
      }

      # Subscribe to main channel
      socket.subscribe(CHANNEL_NAME)

      # Bind to the main channel event 
      socket[CHANNEL_NAME].bind('notification') do |data|

        begin
          data = JSON.parse(data)

          #data.reverse_merge!({
            #"title": "notify-push"
          #})

          message    = data["message"]
          title      = data["title"].nil? ? "notify-push" : data["title"]
          subtitle   = data["subtitle"].nil? ? false : data["subtitle"]

          args = ["-title", title, "-message", message]

          args.concat ["-subtitle", subtitle] if subtitle

          system "terminal-notifier", *args

        rescue => exception
          puts "Warning: Failed to process notification."
          puts exception
        ensure
          puts "----------"
          puts data
        end
      end

      # Bind to the error event
      socket.bind("pusher:error") do |data|
        puts "----------"
        puts "Warning: Pusher Error"
        puts data
      end

      # Connect
      socket.connect

      0
    end


  end
end

# ------------------------------------------------
# TRAP->SIGINT -----------------------------------
# ------------------------------------------------
trap "SIGINT" do
  puts "Exiting"
  exit 130
end
