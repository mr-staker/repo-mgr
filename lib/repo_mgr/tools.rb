# frozen_string_literal: false

require 'colored'

module RepoMgr
  # Holds various tools
  class Tools
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end

    def self.error(msg)
      warn "-- Error: #{msg}".red
      Kernel.exit 1
    end
  end
end
