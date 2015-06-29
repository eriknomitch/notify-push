# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # CLASS->CLI (THOR) ----------------------------
  # ----------------------------------------------
  class CLI < Thor

    desc "receive", "Starts the Receiver daemon."
    option :silence_events, type: :boolean, default: false
    def receive()
      NotifyPush.main :receive
    end

    desc "send MESSAGE <TITLE>", "say receive to NAME"
    def send(message, title="notify-push")

      # FIX: Use these arguments instead of ARGV
      NotifyPush.main :send
    end
    
    #desc "install COMPONENT", "Installs a notify-push component. Available COMPONENTs: receiver-daemon"
    #def install(component)
      #puts "installing..."
    #end
    
    #desc "uninstall COMPONENT", "say receive to NAME"
    #def uninstall(component)
      #puts "installing..."
    #end
  end

end
