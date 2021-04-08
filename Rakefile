require "bundler/audit/task"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# setup task bundle:audit
Bundler::Audit::Task.new

# setup taks rspec
RSpec::Core::RakeTask.new(:rspec) do |t|
  # t.exclude_pattern = "**/server/*_spec.rb" # skip real http server specs
  # t.exclude_pattern = "**/stubbed/*_spec.rb" # skip the stubbed Typhoeus specs
end

# setup taks rubocop and rubocop:auto_correct
RuboCop::RakeTask.new

desc "Open a console with the ChimeraHttpClient loaded"
task :console do
  puts "Console with the gem and amazing_print loaded:"
  ARGV.clear
  require "irb"
  require "ap"
  load "lib/chimera_http_client.rb"
  IRB.start
end

desc "Run rubocop and the specs and check for known CVEs"
task ci: %i(rubocop rspec bundle:audit)

task default: :ci
