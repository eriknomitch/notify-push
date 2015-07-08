# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # MODULE->RECEIVER -----------------------------
  # ----------------------------------------------
  module Receiver

    class << self
      delegate :configuration, to: :parent
    end

    def self.on_at_exit
      notify title: "notify-push", message: "Receiver: Exiting.", sound: :Submarine
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
    def self.notify(title: "notify-push", subtitle: nil, sound: :Bottle, message:)

      message = "#{subtitle} - #{message}" if subtitle

      Notifier.notify({
        title:   title,
        message: message,
        sound:   sound
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
          puts "--------------------------------------------------"
          puts "-> Received Push Notification at: #{Time.now.to_s}"
          puts "--------------------------------------------------"
          ap data
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
        self.notify({
          title:   "notify-push",
          message: "Receiver: Started & connected.",
          sound: :default
        })
      end

      # Connect the Socket
      # ------------------------------------------
      socket.connect

      0
    end

  end
end
