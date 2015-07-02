# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  #class Sub < Thor
    ## --------------------------------------------
    ## CONFIGURATION ------------------------------
    ## --------------------------------------------
    ##package_name "receiver"

    ## --------------------------------------------
    ## COMMAND->RECEIVE ---------------------------
    ## --------------------------------------------
    #desc "Starts the Receiver server (in the foreground)."
    ##option :silence_events, type: :boolean, default: false
    #def foo()
      #puts "foo"
    #end
  #end
  
  # ----------------------------------------------
  # CLASS->CLI-RECEIVER (THOR) -------------------
  # ----------------------------------------------
  #class CLIReceiver < Thor
    
    ## --------------------------------------------
    ## CONFIGURATION ------------------------------
    ## --------------------------------------------
    ##package_name "receiver"

    ## --------------------------------------------
    ## COMMAND->RECEIVE ---------------------------
    ## --------------------------------------------
    ##desc "Starts the Receiver server (in the foreground)."
    #desc "foo", "Starts the Receiver server (in the foreground)."
    ##option :silence_events, type: :boolean, default: false
    #def foo()
      #puts "foo"
    #end

  #end

  # ----------------------------------------------
  # CLASS->CLI (THOR) ----------------------------
  # ----------------------------------------------
  class CLI < Thor

    # --------------------------------------------
    # CONFIGURATION ------------------------------
    # --------------------------------------------
    package_name "notify-push"
    
    # --------------------------------------------
    # COMMAND->UNINSTALL -------------------------
    # --------------------------------------------
    desc "version", "Displays the current version of notify-push"
    def version()
      puts ::NotifyPush::VERSION
    end

    map "--version" => "version"

    # --------------------------------------------
    # COMMAND->RECEIVE ---------------------------
    # --------------------------------------------
    desc "receive", "Starts the Receiver server (in the foreground) (short-cut alias: \"r\")"
    option :silence_events, type: :boolean, default: false

    def receive()
      NotifyPush.main :receive
    end
    
    map "r" => "send"

    # --------------------------------------------
    # COMMAND->SEND ------------------------------
    # --------------------------------------------
    desc "send MESSAGE <TITLE>", "Sends data to any listening Receivers (short-cut alias: \"s\")"
    def send(message, title="notify-push")

      # FIX: Use these arguments instead of ARGV
      NotifyPush.main :send
    end

    map "s" => "send"
    
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

    #desc "subbb", "Installs a notify-push component. Available COMPONENT(s): receiver-daemon"
    #register CLIReceiver, :receiver, "receiver", "Do something else"
    #subcommand "sub", CLIReceiver

  end

end
