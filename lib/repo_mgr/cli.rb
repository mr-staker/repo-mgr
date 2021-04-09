# frozen_string_literal: false

require 'thor'
require 'colored'
require 'fileutils'
require 'terminal-table'

require_relative 'tools'
require_relative 'config'
require_relative 'backends'

module RepoMgr
  # implements CLI interface
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    def self.types
      %w[deb rpm]
    end

    desc 'check-depends', 'Check dependencies'

    def check_depends
      rows = []

      %w[aptly dpkg-sig createrepo rpmsign].each do |bin_dep|
        rows << if Tools.which bin_dep
                  [bin_dep, '✔'.green]
                else
                  [bin_dep, '✘'.red]
                end
      end

      puts Terminal::Table.new headings: %w[Binary Status], rows: rows
    end

    desc 'upsert-repo', 'Create/Update new repository'
    option :name, type: :string, required: true, aliases: %w[-n],
                  desc: 'Name of repository to add'
    option :type, type: :string, required: true, aliases: %w[-t],
                  enum: types, desc: 'Package type'
    option :path, type: :string, required: true, aliases: %w[-p],
                  desc: 'Directory path where to build the repository'
    option :keyid, type: :string, required: true, aliases: %w[-k],
                   desc: 'GPG key id used to sign the repository metadata'

    def upsert_repo
      FileUtils.mkdir_p options[:path]

      config = Config.new
      config.add_repo options[:name], options[:type], options[:path],
                      options[:keyid]

      backend = Backends.load options[:type], config
      backend.add_repo options[:name]

      puts "-- Upserted #{options[:name]} repository"
    end

    desc 'list', 'List existing repositories'

    def list
      rows = []
      config = Config.new

      config.cfg[:repos].each do |name, repo|
        rows << [name, repo[:type], repo[:path], repo[:keyid]]
      end

      return puts '-- No repos have been created' if rows.count.zero?

      puts Terminal::Table.new headings: %w[Name Type Path KeyID], rows: rows
    end

    desc 'add-pkg', 'Add package to repository'
    option :repo, type: :string, required: true, aliases: %w[-r],
                  desc: 'The repository to add the package to'
    option :path, type: :string, required: true, aliases: %w[-p],
                  desc: 'Path to the package to add to a repo'

    def add_pkg
      type = File.extname(options[:path]).strip.downcase[1..-1]

      unless CLI.types.include? type
        Tools.error "unsupported package type #{type}"
      end

      backend = Backends.load type, Config.new
      backend.add_pkg options[:repo], options[:path]

      puts "-- Added #{File.basename(options[:path])} to "\
        "#{options[:repo]} repository"
    end
  end
end
