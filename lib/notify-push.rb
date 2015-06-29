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

end

# ------------------------------------------------
# ------------------------------------------------
# ------------------------------------------------
require "notify-push/receiver"
require "notify-push/sender"

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

