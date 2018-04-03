require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:rspec)

desc "Open a console with the HttpClient loaded"
task :console do
  system "irb -r lib/http_client.rb"
end

desc "Run Rubocop"
task :rubocop do
  system "bundle exec rubocop -c .rubocop.yml"
end

desc "Run Rubocop and auto-correct issues"
task :rubocopa do
  system "bundle exec rubocop -c .rubocop.yml -a"
end

desc "Run all the tests"
task default: %i[rspec rubocop]
