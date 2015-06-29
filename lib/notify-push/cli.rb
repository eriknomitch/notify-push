# ------------------------------------------------
# MODULE->NOTIFY-PUSH ----------------------------
# ------------------------------------------------
module NotifyPush

  # ----------------------------------------------
  # CLASS->CLI (THOR) ----------------------------
  # ----------------------------------------------
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
end
