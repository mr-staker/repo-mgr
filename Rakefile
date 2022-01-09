# frozen_string_literal: false

# Juwelier stuff
begin
  require 'juwelier'

  Juwelier::Tasks.new do |gem|
    gem.name        = 'repo-mgr'
    gem.version     = '0.2.1'
    gem.summary     = %(deb and rpm repository manager)
    gem.description = %(deb and rpm repository manager)
    gem.author      = 'Ștefan Rusu'
    gem.email       = 'saltwaterc@gmail.com'
    gem.files       = %w[bin/repo-mgr LICENSE] + Dir['lib/**/*.rb']
    gem.executables = %w[repo-mgr]
    gem.license     = 'MIT'
    gem.homepage    = 'https://github.com/mr-staker/repo-mgr'
  end
rescue LoadError
  warn 'Juwelier, or one of its dependencies, is not available.'
end

begin
  # Rubocop stuff
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  warn 'Rubocop, or one of its dependencies, is not available.'
end

task cop: %i[rubocop]
task lint: %i[rubocop]

desc 'Remove build artefacts'
task :clean_pkg do
  rm_rf 'pkg'
end

task default: %i[rubocop]
