# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: repo-mgr 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "repo-mgr".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["\u0218tefan Rusu".freeze]
  s.date = "2021-04-14"
  s.description = "deb and rpm repository manager".freeze
  s.email = "saltwaterc@gmail.com".freeze
  s.executables = ["repo-mgr".freeze]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "bin/repo-mgr",
    "lib/repo_mgr.rb",
    "lib/repo_mgr/backends.rb",
    "lib/repo_mgr/backends/deb.rb",
    "lib/repo_mgr/backends/rpm.rb",
    "lib/repo_mgr/cli.rb",
    "lib/repo_mgr/config.rb",
    "lib/repo_mgr/tools.rb"
  ]
  s.homepage = "https://github.com/mr-staker/repo-mgr".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "deb and rpm repository manager".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<colored>.freeze, ["~> 1.2"])
    s.add_runtime_dependency(%q<terminal-table>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<thor>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<jeweler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  else
    s.add_dependency(%q<colored>.freeze, ["~> 1.2"])
    s.add_dependency(%q<terminal-table>.freeze, ["~> 3.0"])
    s.add_dependency(%q<thor>.freeze, ["~> 1.1"])
    s.add_dependency(%q<jeweler>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
  end
end

