require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run Rubocop"
task :rubocop do
  system "bundle exec rubocop -c .rubocop.yml"
end

desc "Run Rubocop and auto-correct issues"
task :rubocopa do
  system "bundle exec rubocop -c .rubocop.yml -a"
end

desc "Run all the tests"
task default: %i[spec rubocop]
