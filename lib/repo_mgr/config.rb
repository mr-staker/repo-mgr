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
      File.write @cfg_file, { repos: {} }.to_yaml unless File.exist? @cfg_file

      @cfg = YAML.load_file @cfg_file
    end

    def save
      File.write @cfg_file, @cfg.to_yaml
    end

    def upsert_repo(name, type, path, keyid)
      if @cfg[:repos][name] && @cfg[:repos][name][:type] != type
        Tools.error "unable to change type for #{name} repository"
      end

      @cfg[:repos][name] = {
        type: type,
        path: path,
        keyid: keyid
      }

      save
    end

    def add_pkg(repo, path)
      if @cfg[:repos][repo].nil?
        Tools.error "unable to add packages to #{repo} - repo does not exist"
      end

      @cfg[:repos][repo][:packages] ||= []
      pkg = File.basename path

      if @cfg[:repos][repo][:packages].include?(pkg)
        Tools.error "you already have #{pkg} in your #{repo} repo"
      end

      @cfg[:repos][repo][:packages] << pkg

      save
    end

    def remove_pkg(repo, path)
      if @cfg[:repos][repo].nil?
        Tools.error "unable to remove packages from #{repo} "\
          '- repo does not exist'
      end

      @cfg[:repos][repo][:packages] ||= []
      pkg = File.basename path
      @cfg[:repos][repo][:packages].delete pkg

      save
    end
  end
end
