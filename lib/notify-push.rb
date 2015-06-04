require "json"
require "shellwords"
require "yaml"
require "recursive-open-struct"
require "os"

require "active_support/core_ext/hash/reverse_merge"
require "active_support/core_ext/module"
require "active_support/core_ext/object/blank"

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

      # The only thing we require is a message.
      # The others will be nil if not supplied.
      raise "No message supplied." if ARGV[0].blank?

      notification = {
        message:  ARGV[0],
        title:    ARGV[1],
        subtitle: ARGV[2]
      }

      # Strip the nil key/value pairs out so we don't have to 
      # worry about them on the Receiver end.
      notification.delete_if {|key, value| value.blank?}

      # Connect to Pusher and trigger the notification
      Pusher.url = "http://#{configuration.pusher.key}:#{configuration.pusher.secret}@api.pusherapp.com/apps/#{configuration.pusher.app_id}"

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
      OS.mac? or "The notify-push receiver only supports OS X."
    end

    # --------------------------------------------
    # NOTIFY -------------------------------------
    # --------------------------------------------
    def self.notify(title: "notify-push", subtitle: nil, message:)

      args = [
        "-message", message,
        "-title",   title
      ]

      args.concat ["-subtitle", subtitle] unless subtitle.blank?

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
