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
        aptly "repo create #{name}" unless aptly_repos.include? name

        repo_config = @config.cfg[:repos][name]

        @aptly_config['FileSystemPublishEndpoints'][name] = {
          rootDir: repo_config[:path],
          linkMethod: 'copy',
          verifyMethod: 'md5'
        }

        save_aptly_config
      end

      def dl_repo(name, url, keyring)
        if keyring.nil?
          Tools.error 'you must specify a keyring file for deb repo'
        end

        keyring = "/usr/share/keyrings/#{keyring}"

        aptly "-keyring=#{keyring} mirror create #{name} #{url} stable main"
        aptly "-keyring=#{keyring} mirror update #{name}", :output
        aptly "repo import #{name} #{name} Name"
        aptly "mirror drop #{name}"
        aptly("repo search #{name}", :return).split.map { |e| "#{e}.deb" }
      end

      def add_pkg(repo, pkg)
        sign_pkg repo, pkg
        repo_add repo, pkg
        repo_publish repo
      end

      def remove_pkg(repo, pkg)
        repo_rm repo, pkg
        repo_publish repo
      end

      def check_sig(pkg, allow_fail: false)
        out, status = Open3.capture2e "dpkg-sig --verify #{pkg}"

        return out if status.exitstatus.zero? || allow_fail

        Tools.error "unable to check package signature for #{pkg} - "\
          "dpkg-sig returned:\n#{out}"
      end

      def sign_pkg(repo, pkg)
        signature = check_sig pkg, allow_fail: true

        unless signature[-6, 5] == 'NOSIG'
          return puts "-- dpkg-sig returned:\n#{signature.split.first}"
        end

        if @config.cfg[:repos][repo].nil?
          Tools.error "unable to find #{repo} repository"
        end

        keyid = @config.cfg[:repos][repo][:keyid]
        out, status = Open3.capture2e "dpkg-sig -k #{keyid} -s builder #{pkg}"

        return if status.exitstatus.zero?

        Tools.error "unable to sign #{pkg} - dpkg-sig returned:\n#{out}"
      end

      def rebuild_pkg_list(repo)
        aptly("-with-packages repo search #{repo}", :return).split.map do |e|
          "#{e}.deb"
        end
      end

      def export(repo)
        repo_publish repo
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

      def aptly(cmd, output = nil)
        cmd = "aptly -config=#{@aptly_config_file} #{cmd}"
        out, status = Open3.capture2e cmd

        Tools.error "#{cmd} failed with:\n#{out}" unless status.exitstatus.zero?

        case output
        when :output
          puts out
        when :return
          out
        end
      end

      def aptly_repos
        aptly('-raw repo list', :return).split
      end

      def aptly_published_repos
        aptly('-raw publish list', :return).split("\n")
      end

      def aptly_publish_drop(repo)
        aptly "publish drop stable filesystem:#{repo}:"
      end

      def save_aptly_config
        File.write @aptly_config_file, @aptly_config.to_json
      end

      def repo_add(repo, pkg)
        aptly "repo add #{repo} #{pkg}"
      end

      def repo_rm(repo, pkg)
        package = File.basename pkg, File.extname(pkg)
        aptly "repo remove #{repo} #{package}"
      end

      def repo_publish(repo)
        if aptly_published_repos.include? "filesystem:#{repo}:. stable"
          aptly_publish_drop(repo)
        end

        keyid = @config.cfg[:repos][repo][:keyid]
        aptly "-distribution=stable -gpg-key=#{keyid} publish repo #{repo} "\
          "filesystem:#{repo}:"
      end
    end
  end
end
