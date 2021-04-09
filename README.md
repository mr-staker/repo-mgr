## About

deb and rpm repository management tool. Essentially, this is a frontend for a suite of tools provided by various distribution maintainers.

repo-mgr provides a unified and consistent way for managing various repositories (deb, rpm).

Features:

 * Create/update deb/rpm repositories.
 * Add packages to these repositories and automatically sign packages using GPG.
 * Repository metadata/manifest signing using GPG.

## Install

```bash
gem install repo-mgr # assumes user install
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
| rpmsign    | ✔      |
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

    n.b `createrepo` is not normally available for Debian and derrivates (including Ubuntu). This tool
    has been used to bootstrap a deb repository which includes a `createrepo` build for Ubuntu 20.04,
    therefore creating a dependency upon itself for setting up rpm repositories.
