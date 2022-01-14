# frozen_string_literal: false

require 'zlib'
require 'open3'
require 'gpgme'
require 'digest'
require 'faraday'
require 'nokogiri'
require 'stringio'
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

        sync_repo repo
      end

      def dl_repo(options)
        name = options[:repo]
        url = options[:url]
        arch = options[:arch]

        Tools.error 'you must specify an arch name for rpm repo' if arch.nil?

        tmpdir = "/tmp/#{name}/#{arch}"
        destdir = "#{@config.cfg_dir}/rpms/#{name}"
        FileUtils.mkdir_p tmpdir
        FileUtils.mkdir_p destdir

        repomd = dl_repomd url, arch, tmpdir
        pkgs = dl_primary url, arch, tmpdir, repomd

        pkgs.each do |hash, file|
          dl_pkg hash, url, arch, file, tmpdir
          copy_pkg "#{tmpdir}/#{file}", destdir
        end

        pkgs.values
      end

      def remove_pkg(repo, pkg)
        name = File.basename pkg
        arch = extract_arch pkg
        dest_dir = "#{@config.cfg_dir}/rpms/#{repo}/#{arch}"

        FileUtils.rm_f "#{dest_dir}/#{name}"

        sync_repo repo
      end

      def check_sig(pkg)
        out, status = Open3.capture2e "rpm -K #{pkg}"

        return out if status.exitstatus.zero?

        Tools.error "unable to check package signature for #{pkg} - "\
          "rpm -K returned:\n#{out}"
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

      def rebuild_pkg_list(repo)
        Dir["#{@config.cfg_dir}/rpms/#{repo}/**/*.rpm"].map do |e|
          File.basename e
        end
      end

      def export(repo)
        sync_repo repo
      end

      private

      def extract_arch(pkg)
        pkg.split('.')[-2]
      end

      def sync_repo(repo)
        repo_dir = @config.cfg[:repos][repo][:path]

        Dir["#{@config.cfg_dir}/rpms/#{repo}/*"].each do |arch_dir|
          arch = File.basename arch_dir
          arch_dest = "#{repo_dir}/#{arch}"

          FileUtils.rm_rf arch_dest
          FileUtils.mkdir_p arch_dest

          Dir["#{@config.cfg_dir}/rpms/#{repo}/#{arch}/*.rpm"].each do |rpm|
            FileUtils.cp rpm, arch_dest
          end

          Dir.chdir arch_dest do
            build_repo arch
            Dir.chdir('repodata') { sign_repo repo }
          end
        end
      end

      def build_repo(arch)
        cmd = 'createrepo --zck --verbose --update .'

        out, status = Open3.capture2e cmd

        return if status.exitstatus.zero?

        Tools.error "unable to create repo for #{arch} - createrepo "\
          "returned:\n#{out}"
      end

      def sign_repo(repo)
        keyid = @config.cfg[:repos][repo][:keyid]

        data = GPGME::Data.new File.read('repomd.xml')
        opt = {
          armor: true,
          signer: keyid,
          mode: GPGME::SIG_MODE_DETACH
        }

        signature = GPGME::Crypto.sign data, opt

        File.write 'repomd.xml.asc', signature
      end

      def faraday_dl(url, tmpdir, file = File.basename(url))
        puts "-- Download #{file}"
        File.write "#{tmpdir}/#{file}", Faraday.get(url).body
      end

      def dl_repomd(url, arch, tmpdir)
        faraday_dl "#{url}/#{arch}/repodata/repomd.xml", tmpdir
        faraday_dl "#{url}/#{arch}/repodata/repomd.xml.asc", tmpdir

        valid = false
        crypto = GPGME::Crypto.new armor: true
        sig = GPGME::Data.new File.read "#{tmpdir}/repomd.xml.asc"
        data = File.read "#{tmpdir}/repomd.xml"
        crypto.verify(sig, signed_text: data) do |sign|
          valid = sign.valid?
        end

        unless valid == true
          Tools.error "unable to check signature for #{tmpdir}/repomd.xml"
        end

        Nokogiri::XML data
      end

      def extract_pkgs(primary)
        pkgs = {}

        primary.css('package').each do |pkg|
          pkg_hash = pkg.at('checksum[type=sha256]').text
          pkgs[pkg_hash] = pkg.at('location')['href']
        end

        pkgs
      end

      def dl_primary(url, arch, tmpdir, repomd)
        hash = repomd.at('data[type=primary]').at('checksum').text
        primary = "#{url}/#{arch}/repodata/#{hash}-primary.xml.gz"

        faraday_dl primary, tmpdir, 'primary.xml.gz'

        primary_xml_gz = "#{tmpdir}/primary.xml.gz"
        fl_hash = Digest::SHA256.hexdigest(File.read(primary_xml_gz))

        unless fl_hash == hash
          Tools.error "failed hash check for #{tmpdir}/primary.xml.gz"
        end

        primary_xml_gz = File.read("#{tmpdir}/primary.xml.gz")
        primary = Zlib::GzipReader.new(StringIO.new(primary_xml_gz)).read
        File.write("#{tmpdir}/primary.xml", primary)

        extract_pkgs Nokogiri::XML(primary)
      end

      def dl_pkg(hash, url, arch, file, tmpdir)
        unless File.exist? "#{tmpdir}/#{file}"
          faraday_dl "#{url}/#{arch}/#{file}", tmpdir
        end

        fl_hash = Digest::SHA256.hexdigest(File.read("#{tmpdir}/#{file}"))

        return if fl_hash == hash

        Tools.error "failed hash check for #{tmpdir}/#{file}"
      end

      def copy_pkg(file, destdir)
        puts "-- Copy to repo-mgr #{File.basename(file)}"
        FileUtils.cp file, destdir
      end
    end
  end
end
