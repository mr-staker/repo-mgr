# frozen_string_literal: false

require 'yaml'
require 'fileutils'

require_relative 'tools'

module RepoMgr
  # handles repo-mgr configuration
  class Config
    attr_reader :cfg, :cfg_dir

    def initialize
      @cfg_dir = "#{ENV['HOME']}/.repo-mgr"
      FileUtils.mkdir_p @cfg_dir

      @cfg_file = "#{@cfg_dir}/repo-mgr.yml"
      unless File.exist? @cfg_file
        File.write @cfg_file, { repos: {}, packages: {} }.to_yaml
      end

      @cfg = YAML.load_file @cfg_file
    end

    def save
      File.write @cfg_file, @cfg.to_yaml
    end

    def upsert_repo(options)
      name = options[:name]
      type = options[:type]

      if @cfg[:repos][name] && @cfg[:repos][name][:type] != type
        Tools.error "unable to change type for #{name} repository"
      end

      @cfg[:repos][name] = {
        type: type,
        path: options[:path],
        keyid: options[:keyid]
      }

      if options[:publisher]
        @cfg[:repos][name][:publisher] = options[:publisher]
      end

      save
    end

    def add_pkg(repo, path)
      if @cfg[:repos][repo].nil?
        Tools.error "unable to add packages to #{repo} - repo does not exist"
      end

      @cfg[:packages] ||= {}
      @cfg[:packages][repo] ||= []
      pkg = File.basename path

      if @cfg[:packages][repo].include?(pkg)
        Tools.error "you already have #{pkg} in your #{repo} repo"
      end

      @cfg[:packages][repo] << pkg

      save
    end

    def remove_pkg(repo, path)
      if @cfg[:repos][repo].nil?
        Tools.error "unable to remove packages from #{repo} "\
                    '- repo does not exist'
      end

      @cfg[:packages] ||= {}
      @cfg[:packages][repo] ||= []
      pkg = File.basename path
      @cfg[:packages][repo].delete pkg

      save
    end
  end
end
