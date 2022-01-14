## About

deb and rpm repository management tool. Essentially, this is a frontend for a suite of tools provided by various distribution maintainers.

repo-mgr provides a unified and consistent way for managing various repositories (deb, rpm).

Features:

 * Create/update deb/rpm repositories.
 * Add/remove packages to these repositories and automatically sign packages using GPG.
 * Repository metadata/manifest signing using GPG.
 * Publish to remote via git.

To simplify things:

 * aptly (which, kind of obviously, manages deb repositories) uses "stable" as distribution and "main" as component.
 * The git publisher uses the `main` branch for `sync` only.

The requred aptly version is 1.4.0+ which may be installed from [aptly's deb repository](https://www.aptly.info/download/). The version available in Ubuntu 20.04 (1.3.0) doesn't support gpg2.

## Install

```bash
# RubyGems
gem install repo-mgr

# from source
rake install
```

As repo-mgr is a frontend for other tools, there are dependencies which must be installed separately. It is not compulsory to install all dependencies, only those needed for a particular use case. The purpose for each tool is explained by `check-depends`.

To check which dependencies are required based on use case and their status:

```bash
repo-mgr check-depends
+------------+--------+-----------------------+
| Binary     | Status | Purpose               |
+------------+--------+-----------------------+
| aptly      | ✔      | Manage apt repository |
| dpkg-sig   | ✔      | Sign deb packages     |
| createrepo | ✔      | Manage rpm repository |
| rpm        | ✔      | Sign rpm packages     |
| git        | ✔      | Use git publisher     |
+------------+--------+-----------------------+
```

For managing deb repositories:

```bash
sudo apt install aptly dpkg-sig
```

For managing rpm repositories:

```bash
sudo apt install createrepo rpm
```

For using the git publisher:

```bash
sudo apt install git
```

    n.b `createrepo` is not normally available for Debian and derrivates (including Ubuntu). This tool
    has been used to bootstrap a deb repository which includes a `createrepo` build for Ubuntu 20.04,
    therefore creating a dependency upon itself for setting up rpm repositories.

You can get our build of createrepo from our [deb repository](https://deb.staker.ltd/).

Pro tip: if the pkg signing fails because gpg can't open the output device, add this to your shell config:

```bash
export GPG_TTY=$(tty)
```

## How to use

```bash
# to get you started
repo-mgr help

# create repo
## --path => a local directory where the repository is published - no remote support at the moment
## GPGKEYID is expected as log keyid i.e 16 hex chars
## --publisher - is optional i.e you can still manually publish a local repository
repo-mgr upsert-repo --name foo --type deb --path path/to/foo --keyid GPGKEYID --publisher git

# sign package, add to repository, and update local repo (includes sign repo release manifest)
# the local repo is exported to the path indicated in upsert-repo
# the git publisher also commits the changes as the path for upsert-repo is expected to be
# a git repository
repo-mgr add-pkg --repo foo --path path/to/bar_0.0.1_amd64.deb

# publish the repository to a remote - for git publisher this means doing git push
repo-mgr sync --repo foo

# download repo from remote e.g when changing development machines
# repo-mgr upsert-repo (...) # needed only once if the machine is brand new
## --url must point to the root of the remote repository
## i.e where the pool and dists directories can be found for deb repos
## --keyring is required for deb repositories; it is a file from
## /usr/share/keyrings - the base path is automatically prepended
## WARNING: the packages are not signed when imported via this method!
repo-mgr dl-repo --repo foo --type deb --url https://apt.example.com --keyring foo-keyring.gpg

## --arch must be specified as each rpm repo arch is self-contained
## the remote repository gpg key must be imported into the user's keyring and trusted
## prior to starting the import process from remote rpm repo
repo-mgr dl-repo --repo foo --type rpm --url https://rpm.example.com --arch x86_64
```

## Migrating from v0.1

The package list is stored into a structure that's prone to lose the list upon re-running `upsert-repo` for `v0.1.x` of this gem. For this reason, the package list data structure has been redesigned within repo-mgr's config file.

So, to migrate from this earlier version, you must run, for every repo:

```bash
repo-mgr rebuild-pkg-list --repo foo
```

This rebuilds the data structure in the new config location.
