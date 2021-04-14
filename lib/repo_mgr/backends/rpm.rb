# frozen_string_literal: false

require 'open3'
require 'gpgme'
require 'fileutils'

module RepoMgr
  module Backend
    # rpm backend handler
    class Rpm
      def initialize(config)
        @config = config
      end

      # this is managed from RepoMgr::Config
      def add_repo(_name); end

      def add_pkg(repo, pkg)
        sign_pkg repo, pkg

        arch = extract_arch pkg
        dest_dir = "#{@config.cfg_dir}/rpms/#{repo}/#{arch}"

        FileUtils.mkdir_p dest_dir
        FileUtils.cp pkg, dest_dir
      end

      def remove_pkg(repo, pkg)
        name = File.basename pkg
        arch = extract_arch pkg
        dest_dir = "#{@config.cfg_dir}/rpms/#{repo}/#{arch}"

        FileUtils.rm_f "#{dest_dir}/#{name}"
      end

      def check_sig(pkg)
      end

      def sign_pkg(repo, pkg)
        keyid = @config.cfg[:repos][repo][:keyid]
        gpg_name = GPGME::Key.find(keyid).first.uids.first.uid

        # need to deal with the %_gpg_name nonsense as adding that via CLI is
        # too bloody much for ARRRRRRRRRR PM - also who in their right mind
        # would target a key by name / email rather than, you know, key ID

        rpm_macros = "#{ENV['HOME']}/.rpmmacros"
        File.write rpm_macros, "%_gpg_name #{gpg_name}"

        # gpg-agent? nah - rpm is special
        cmd = "rpm --addsign #{pkg}"

        out, status = Open3.capture2e cmd

        FileUtils.rm_f rpm_macros

        return if status.exitstatus.zero?

        Tools.error "unable to sign #{pkg} - rpm --addsign returned:\n#{out}"
      end

      def sign_repo(repo)
      end

      private

      def extract_arch(pkg)
        pkg.split('.')[-2]
      end
    end
  end
end
