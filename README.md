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

## Install

```bash
# RubyGems
gem install repo-mgr

# from source
rake install
```

As repo-mgr is a frontend for other tools, there's dependencies which must be installed separately.

To check which dependencies are required and their status:

```bash
repo-mgr check-depends
+------------+--------+
| Binary     | Status |
+------------+--------+
| aptly      | ✔      |
| dpkg-sig   | ✔      |
| createrepo | ✔      |
| rpm        | ✔      |
| git        | ✔      |
+------------+--------+
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

## How to use

```bash
# to get you started
repo-mgr help

# create repo
## --path => a local directory where the repository is published - no remote support at the moment
## GPGKEYID is expected as log keyid i.e 16 hex chars
repo-mgr upsert-repo --name foo --type deb --path path/to/foo --keyid GPGKEYID --publisher git

# sign package, add to repository, and update local repo (includes sign repo release manifest)
# the local repo is exported to the path indicated in upsert-repo
# the git publisher also commits the changes as the path for upsert-repo is expected to be
# a git repository
repo-mgr add-pkg --repo foo --path path/to/bar_0.0.1_amd64.deb

# publish the repository to a remote - for git publisher this means doing git push
repo-mgr sync --repo foo
```
