require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

$:.unshift(File.dirname(__FILE__))

desc "run server locally"
task :server => "Gemfile.lock" do
  require 'server'
  Sinatra::Application.run!
end