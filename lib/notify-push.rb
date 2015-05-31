require "dotenv"
require "pusher"

Dotenv.load

module NotifyPush
  def self.start_sender()
    Pusher.url = "http://#{ENV["PUSHER_KEY"]}:#{ENV["PUSHER_SECRET"]}@api.pusherapp.com/apps/#{ENV["PUSHER_APP_ID"]}"

    Pusher['test_channel'].trigger('my_event', {
      message: 'hello world'
    })
  end
end
