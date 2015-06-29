require "json"
require "shellwords"
require "yaml"
require "recursive-open-struct"
require "os"
require "notifier"
require "thor"

# FIX: Development only
require "pry" if Gem::Specification::find_all_by_name("pry").any?

require "active_support/core_ext/hash/reverse_merge"
require "active_support/core_ext/module"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/inflector/inflections"

# ------------------------------------------------
# TRAP->ANY-EXIT ---------------------------------
# ------------------------------------------------
at_exit { NotifyPush.on_at_exit }

# ------------------------------------------------
# ->CLASS->OS ------------------------------------
# ------------------------------------------------
class OS
  def self.host_simple
    # FIX: Add more.
    %i(mac linux windows).each do |os|
      return os if OS.send("#{os}?")
    end or raise "Cannot detect OS."
  end
end

# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush
  
  # ----------------------------------------------
  # CONSTANTS ------------------------------------
  # ----------------------------------------------
  CHANNEL_NAME            = "notify-push"
  CONFIGURATION_FILE_PATH = "#{ENV["HOME"]}/.notify-pushrc"
 
  # ----------------------------------------------
  # ATTRIBUTES -----------------------------------
  # ----------------------------------------------
  mattr_accessor :configuration, :acting_as

  # ----------------------------------------------
  # MODULE->UTILITY ------------------------------
  # ----------------------------------------------
  module Utility
    def self.require_system_command_or_raise(command)
      system "command -v #{command} >/dev/null 2>&1" or raise "The command '#{command}' cannot be found and is required."
    end
  end

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
  # CALLBACKS ------------------------------------
  # ----------------------------------------------
  def self.on_at_exit
    self.acting_as.try(:on_at_exit)
    puts "Exiting."
  end
  
  # ----------------------------------------------
  # MAIN -----------------------------------------
  # ----------------------------------------------
  def self.main(type, *args)
    begin
      initialize_configuration

      case type
      when :receiver, :receive
        return NotifyPush::Receiver.start *args
      when :sender, :send
        return NotifyPush::Sender.send_notification *args
      end

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

  # ----------------------------------------------
  # MODULE->RECEIVER -----------------------------
  # ----------------------------------------------
  module Receiver

    class << self
      delegate :configuration, to: :parent
    end

    def self.on_at_exit
      notify title: "notify-push", message: "Receiver: Exiting."
    end

    # --------------------------------------------
    # PID ----------------------------------------
    # --------------------------------------------
    def self.pid_lock
      require "pidfile"

      PidFile.new
    end

    # --------------------------------------------
    # NOTIFY -------------------------------------
    # --------------------------------------------
    def self.notify(title: "notify-push", subtitle: nil, message:)

      message = "#{subtitle} - #{message}" if subtitle

      Notifier.notify({
        title:   title,
        message: message
      })
    end
  
    # --------------------------------------------
    # START --------------------------------------
    # --------------------------------------------
    def self.start()

      pid_lock

      ::NotifyPush.acting_as = self

      require "pusher-client"

      socket = PusherClient::Socket.new configuration.pusher.key, {
        secure: true
      }

      # Subscribe to main channel
      # ------------------------------------------
      socket.subscribe(CHANNEL_NAME)

      # Bind to: Main Channel Notification
      # ------------------------------------------
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

      # Bind to: Pusher Errors
      # ------------------------------------------
      socket.bind("pusher:error") do |data|
        puts "----------"
        puts "Warning: Pusher Error"
        puts data
      end
     
      # Bind to: Pusher Connection Established
      # ------------------------------------------
      socket.bind("pusher:connection_established") do |data|
        Notifier.notify({
          title:   "notify-push",
          message: "Receiver: Started & connected."
        })
      end

      # Connect the Socket
      # ------------------------------------------
      socket.connect

      0
    end

  end
end

# ------------------------------------------------
# CLASS->CLI (THOR) ------------------------------
# ------------------------------------------------
class CLI < Thor

  desc "receive", "Starts the Receiver daemon."
  def receive()
    NotifyPush.main :receive
  end

  desc "send TITLE MESSAGE", "say receive to NAME"
  def send(title="", message="")

    # FIX: Use these arguments instead of ARGV
    NotifyPush.main :send
  end
end

# ------------------------------------------------
# MAIN -------------------------------------------
# ------------------------------------------------
CLI.start(ARGV)

