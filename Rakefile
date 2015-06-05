# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "notify-push"
  gem.homepage = "http://github.com/eriknomitch/notify-push"
  gem.license = "MIT"
  gem.summary = %Q{A general purpose popup notifier sender/receiver using WebSockets (via Pusher)}
  gem.description = "A general purpose popup notifier sender/receiver using WebSockets (via Pusher)"
  gem.email = "erik@nomitch.com"
  gem.authors = ["Erik Nomitch"]
  gem.licenses = ["GPL-2"]
  gem.post_install_message = <<-EOS
---------------------------------------------------------------
If you have not done so, you will need to create a configuration file at:

~/.notify-pushrc

See the instructions/example at:

https://github.com/eriknomitch/notify-push#create--distribute-configuration-file

Or, modify this example.  It's pretty straightforward:

pusher:
  key: a1a2a3b1b2b3c1c2c3d1
  secret: a1a2a3b1b2b3c1c3c1d1
  app_id: 12345

---------------------------------------------------------------
  EOS

  #s.files = `git ls-files`.split("\n")
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "notify-push #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
