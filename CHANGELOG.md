## v0.3.1

 * Fix GPG key seeking for RPM repos. `GPGME::Key.find` is less reliable than `GPGME::Key.get`.

## v0.3.0

 * Add remote repo downloader.
 * Update dependencies to solve security problems.

## v0.2.1

 * Add repo exporter to rebuild a local repo.

## v0.2.0

 * Add git publisher.
 * Fix issue with upsert-repo which wipes package list.
 * Add rebuild-pkg-list CLI subcommand to rebuild pkg list from repo-mgr pkg cache.

## v0.1.1

 * Fix add-pkg for deb repos. Exposing the signature checker via CLI broke the internal use case.

## v0.1.0

 * Initial release.
