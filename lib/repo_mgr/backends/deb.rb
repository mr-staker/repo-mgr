# frozen_string_literal: false

require 'json'
require 'open3'
require 'fileutils'

module RepoMgr
  module Backend
    # deb backend handler implemented on top of aptly
    class Deb
      def initialize(config)
        @config = config
        init_aptly_config
      end

      def add_repo(name)
        return if aptly_repos.include? name

        cmd = "aptly -config=#{@aptly_config_file} repo create #{name}"
        out, status = Open3.capture2e cmd

        unless status.exitstatus.zero?
          Tools.error "aptly repo create failed with:\n#{out}"
        end

        repo_config = @config.cfg[:repos][name]

        @aptly_config['FileSystemPublishEndpoints'][name] = {
          rootDir: repo_config[:path],
          linkMethod: 'copy',
          verifyMethod: 'md5'
        }

        save_aptly_config
      end

      def add_pkg(repo, pkg)
        sign_pkg repo, pkg
        repo_add repo, pkg
        repo_publish repo
        sign_repo repo
      end

      def remove_pkg(repo, pkg)
        repo_rm repo, pkg
        repo_publish repo
      end

      def check_sig(pkg)
        out, status = Open3.capture2e "dpkg-sig --verify #{pkg}"

        return out if status.exitstatus.zero?

        Tools.error "unable to check package signature for #{pkg} - "\
          "dpkg-sig returned:\n#{out}"
      end

      def sign_pkg(repo, pkg)
        signature = check_sig(pkg)
        unless signature.first[-6, 5] == 'NOSIG'
          return puts "-- dpkg-sig returned:\n#{signature.first}"
        end

        if @config.cfg[:repos][repo].nil?
          Tools.error "unable to find #{repo} repository"
        end

        keyid = @config.cfg[:repos][repo][:keyid]
        out, status = Open3.capture2e "dpkg-sig -k #{keyid} -s builder #{pkg}"

        return if status.exitstatus.zero?

        Tools.error "unable to sign #{pkg} - dpkg-sig returned:\n#{out}"
      end

      def sign_repo(repo)
        puts "-- Signed repo #{repo}"
      end

      private

      def init_aptly_config
        @aptly_root = "#{@config.cfg_dir}/aptly"
        @aptly_config_file = "#{@config.cfg_dir}/aptly.json"

        unless File.exist? @aptly_config_file
          File.write @aptly_config_file, aptly_base_config.to_json
        end

        @aptly_config = JSON.parse File.read(@aptly_config_file)
      end

      # rubocop:disable Metrics/MethodLength
      def aptly_base_config
        FileUtils.mkdir_p @aptly_root

        {
          rootDir: @aptly_root,
          downloadConcurrency: 4,
          downloadSpeedLimit: 0,
          architectures: [],
          dependencyFollowSuggests: false,
          dependencyFollowRecommends: false,
          dependencyFollowAllVariants: false,
          dependencyFollowSource: false,
          dependencyVerboseResolve: false,
          gpgDisableSign: false,
          gpgDisableVerify: false,
          # despite the binary being gpg, this must spell gpg2, otherwise aptly
          # defaults to gpg1 with less than impressive results
          gpgProvider: 'gpg2',
          downloadSourcePackages: false,
          skipLegacyPool: true,
          ppaDistributorID: '',
          ppaCodename: '',
          skipContentsPublishing: false,
          FileSystemPublishEndpoints: {},
          S3PublishEndpoints: {},
          SwiftPublishEndpoints: {}
        }
      end
      # rubocop:enable Metrics/MethodLength

      def aptly_repos
        cmd = "aptly -raw -config=#{@aptly_config_file} repo list"
        out, status = Open3.capture2e cmd

        unless status.exitstatus.zero?
          Tools.error "aptly repo list failed with:\n#{out}"
        end

        out.split("\n")
      end

      def aptly_published_repos
        cmd = "aptly -raw -config=#{@aptly_config_file} publish list"
        out, status = Open3.capture2e cmd

        unless status.exitstatus.zero?
          Tools.error "aptly publish list failed with:\n#{out}"
        end

        out.split("\n")
      end

      def aptly_publish_drop(repo)
        cmd = "aptly -config=#{@aptly_config_file} publish drop stable "\
          "filesystem:#{repo}:"
        out, status = Open3.capture2e cmd

        return if status.exitstatus.zero?

        Tools.error "aptly publish drop failed with:\n#{out}"
      end

      def save_aptly_config
        File.write @aptly_config_file, @aptly_config.to_json
      end

      def repo_add(repo, pkg)
        cmd = "aptly -config=#{@aptly_config_file} repo add #{repo} #{pkg}"
        out, status = Open3.capture2e cmd

        return if status.exitstatus.zero?

        Tools.error "aptly repo add failed with:\n#{out}"
      end

      def repo_rm(repo, pkg)
        package = File.basename pkg, File.extname(pkg)
        cmd = "aptly -config=#{@aptly_config_file} repo remove "\
          "#{repo} #{package}"
        out, status = Open3.capture2e cmd

        return if status.exitstatus.zero?

        Tools.error "aptly repo remove failed with:\n#{out}"
      end

      def repo_publish(repo)
        if aptly_published_repos.include? "filesystem:#{repo}:. stable"
          aptly_publish_drop(repo)
        end

        keyid = @config.cfg[:repos][repo][:keyid]
        cmd = "aptly -config=#{@aptly_config_file} -distribution=stable "\
          "-gpg-key=#{keyid} publish repo #{repo} filesystem:#{repo}:"

        out, status = Open3.capture2e cmd

        return if status.exitstatus.zero?

        Tools.error "aptly publish repo failed with:\n#{out}"
      end
    end
  end
end
