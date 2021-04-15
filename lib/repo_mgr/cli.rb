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
      config.upsert_repo options[:name], options[:type], options[:path],
                         options[:keyid]

      backend = Backends.load options[:type], config
      backend.add_repo options[:name]

      puts "-- Upserted #{options[:name]} repository"
    end

    desc 'list-repos', 'List existing repositories'

    def list_repos
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
      backend, config = load_backend options[:path]
      backend.add_pkg options[:repo], options[:path]
      config.add_pkg options[:repo], options[:path]

      puts "-- Added #{File.basename(options[:path])} to "\
        "#{options[:repo]} repository"
    end

    desc 'list-pkgs', 'List repository packages'
    option :repo, type: :string, required: true, aliases: %w[-r],
                  desc: 'The repository to list the packages from'

    def list_pkgs
      packages = Config.new.cfg[:repos][options[:repo]][:packages]

      if packages.nil?
        Tools.error "#{options[:repo]} repo does not have any packages"
      end

      rows = packages.sort.each_with_index.map { |e, i| [i + 1, e] }

      puts Terminal::Table.new headings: ['#', "Packages in #{options[:repo]}"],
                               rows: rows
    end

    desc 'remove-pkg', 'Remove a package from a repository'
    option :repo, type: :string, required: true, aliases: %w[-r],
                  desc: 'The repository to add the package to'
    option :path, type: :string, required: true, aliases: %w[-p],
                  desc: 'Path to the package to add to a repo'

    def remove_pkg
      backend, config = load_backend options[:path]
      backend.remove_pkg options[:repo], options[:path]
      config.remove_pkg options[:repo], options[:path]

      puts "-- Removed #{File.basename(options[:path])} from "\
        "#{options[:repo]} repository"
    end

    desc 'check-sig', 'Check package signature'
    option :path, type: :string, required: true, aliases: %w[-p],
                  desc: 'Path to the the package to check signature'

    def check_sig
      backend, _config = load_backend options[:path]
      puts backend.check_sig options[:path]
    end

    private

    def load_backend(path)
      type = File.extname(path).strip.downcase[1..-1]

      unless CLI.types.include? type
        Tools.error "unsupported package type #{type}"
      end

      config = Config.new

      [Backends.load(type, config), config]
    end
  end
end
