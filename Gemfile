# ================================================
# GEMFILE ========================================
# ================================================
source "http://rubygems.org"

# http://stackoverflow.com/questions/8420414/how-to-add-mac-specific-gems-to-bundle-on-mac-but-not-on-linux
def windows_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /mingw|mswin/i ? require_as : false
end

def linux_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /linux/ ? require_as : false
end

def darwin_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /darwin/ ? require_as : false
end

gem "pusher"
gem "pusher-client"
gem "activesupport"
gem "recursive-open-struct"
gem "pidfile"
gem "os"
gem "terminal-notifier", require: darwin_only("terminal-notifier")

group :development do
  gem "shoulda", ">= 0"
  gem "rdoc", "~> 3.12"
  gem "yard", "~> 0.7"
  gem "bundler", "~> 1.0"
  gem "jeweler", "~> 2.0.1"
  gem "simplecov", ">= 0"
end
