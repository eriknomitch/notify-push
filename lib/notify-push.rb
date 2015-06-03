require "json"
require "shellwords"
require "yaml"
require "recursive-open-struct"
require "active_support/core_ext/hash/reverse_merge"
require "active_support/core_ext/module"

# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush
  
  # ----------------------------------------------
  # ATTRIBUTES -----------------------------------
  # ----------------------------------------------
  mattr_accessor :configuration

  # ----------------------------------------------
  # CONSTANTS ------------------------------------
  # ----------------------------------------------
  CHANNEL_NAME            = "notify-push"
  CONFIGURATION_FILE_PATH = "#{ENV["HOME"]}/.notify-pushrc"
  
  # ----------------------------------------------
  # USER-CONFIGURATION ---------------------------
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
  def self.main()
    begin
      initialize_configuration

      if ["--receiver", "-r"].member? ARGV[0]
        return NotifyPush::Receiver.start
      end

      NotifyPush::Sender.start
    rescue => exception
      puts "fatal: #{exception.to_s}"
      exit 1
    end
  end

  # ----------------------------------------------
  # MODULE->SENDER -------------------------------
  # ----------------------------------------------
  module Sender

    class << self
      delegate :configuration, to: :parent
    end

    def self.start()
      require "pusher"

      raise "No message supplied." if ARGV.length == 0

      Pusher.url = "http://#{configuration.pusher.key}:#{configuration.pusher.secret}@api.pusherapp.com/apps/#{configuration.pusher.app_id}"

      notification = {message: ARGV[0]}

      notification[:title] = ARGV[1] if ARGV[1]
      
      Pusher[CHANNEL_NAME].trigger("notification", notification)

      0
    end
  end

  # ----------------------------------------------
  # MODULE->RECEIVER -----------------------------
  # ----------------------------------------------
  module Receiver

    class << self
      delegate :configuration, to: :parent
    end

    # --------------------------------------------
    # PID ----------------------------------------
    # --------------------------------------------
    def self.pid_lock
      require "pidfile"

      PidFile.new
    end

    # --------------------------------------------
    # ENSURANCES ---------------------------------
    # --------------------------------------------
    def self.ensure_dependencies
      system "command -v terminal-notifier >/dev/null 2>&1" or raise "'terminal-notifier' cannot be found."
    end

    def self.ensure_compatibility
      `uname`.chomp("\n") == "Darwin" or "The notify-push receiver only supports OS X."
    end

    # --------------------------------------------
    # NOTIFY -------------------------------------
    # --------------------------------------------
    def self.notify(title: "notify-push", subtitle: nil, message: " ")

      args = ["-title", title, "-message", message]

      args.concat ["-subtitle", subtitle] if subtitle

      system "terminal-notifier", *args
    end

    # --------------------------------------------
    # START --------------------------------------
    # --------------------------------------------
    def self.start()

      ensure_compatibility
      ensure_dependencies
      pid_lock

      require "pusher-client"

      socket = PusherClient::Socket.new configuration.pusher.key, {
        secure: true
      }

      # Subscribe to main channel
      socket.subscribe(CHANNEL_NAME)

      # Bind to the main channel event 
      socket[CHANNEL_NAME].bind("notification") do |data|

        begin
          data = JSON.parse(data, symbolize_names: true)
          
          notify **data

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
  puts "Exiting."
  exit 130
end
