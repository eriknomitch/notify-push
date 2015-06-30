# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # CLASS->CLI (THOR) ----------------------------
  # ----------------------------------------------
  class CLI < Thor

    # --------------------------------------------
    # CONFIGURATION ------------------------------
    # --------------------------------------------
    package_name "notify-push"

    # --------------------------------------------
    # COMMAND->RECEIVE ---------------------------
    # --------------------------------------------
    desc "receive", "Starts the Receiver server (in the foreground)."
    option :silence_events, type: :boolean, default: false
    def receive()
      NotifyPush.main :receive
    end

    # --------------------------------------------
    # COMMAND->SEND ------------------------------
    # --------------------------------------------
    desc "send MESSAGE <TITLE>", "Sends data to any listening Receivers."
    def send(message, title="notify-push")

      # FIX: Use these arguments instead of ARGV
      NotifyPush.main :send
    end
    
    # --------------------------------------------
    # COMMAND->INSTALL ---------------------------
    # --------------------------------------------
    desc "install COMPONENT", "Installs a notify-push component. Available COMPONENT(s): receiver-daemon"
    def install(component)
      puts "installing..."
    end
    
    # --------------------------------------------
    # COMMAND->UNINSTALL -------------------------
    # --------------------------------------------
    desc "uninstall COMPONENT", "Uninstalls a notify-push component."
    def uninstall(component)
      puts "uninstalling..."
    end
  end

end
