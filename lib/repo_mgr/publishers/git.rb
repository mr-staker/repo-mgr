# frozen_string_literal: false

require 'git'

module RepoMgr
  module Publisher
    # git publisher
    class Git
      def initialize(config)
        @config = config
      end

      # method invoked when the local deb/rpm repository is built
      # for git, this requires a commit into the target git repository
      # which is the target for deb/rpm repository export
      def save(repo, pkg)
        git = ::Git.open @config.cfg[:repos][repo][:path]
        git.add(all: true)
        git.commit "Add #{File.basename(pkg)}."
      end

      # method invoked when the local deb/rpm repository is published
      # for git, this is pushing to a remote
      def sync(repo)
        git = ::Git.open @config.cfg[:repos][repo][:path]
        git.push(git.remote('origin'), 'main')
      end
    end
  end
end
