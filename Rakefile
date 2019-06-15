require "bundler/audit/task"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

Bundler::Audit::Task.new

RSpec::Core::RakeTask.new(:rspec) do |t|
  # t.exclude_pattern = "**/server/*_spec.rb" # skip real http server specs
  # t.exclude_pattern = "**/stubbed/*_spec.rb" # skip the stubbed Typhoeus specs
end

desc "Open a console with the ChimeraHttpClient loaded"
task :console do
  puts "Console with the gem and awesome_print loaded:"
  ARGV.clear
  require "irb"
  require "ap"
  load "lib/chimera_http_client.rb"
  IRB.start
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
task default: %i[rspec rubocop bundle:audit]
