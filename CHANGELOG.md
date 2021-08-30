# Changelog

All notable changes will be documented in this file.

The format is based on [Keep a Changelog][keepachangelog], and this project
adheres to [Semantic Versioning][semver].

## [Unreleased]

## [0.7.1] - 2021-08-30
### Fixed
- Backport of default drops to `:restrict` are now backwards compatible with older versions of `ecto_sql`. We don't really have support for `drop index ... cascade` as it is not in the grammer of sqlite.

## [0.7.0] - 2021-08-27
### Changed
- Update dependencies to the latest.
- Drop support for OTP 20. It is not supported by `telemetry` and won't compile. For now we will just support Elixir 1.8 and OTP 21.


## [0.6.1] - 2021-08-27
### Changed
- UUID encoding for both `:binary_id` and `:uuid`/`Ecto.UUID` is now configurable
- `:uuid`/`Ecto.UUID` is now encoded as a string by default


## [0.6.0] - 2021-08-25
### Changed
- `:utc_datetime` handling has been updated to completely remove the `Z` supplied and made to conform closer to what is done for Postgrex and MyXQL. [#49](https://github.com/elixir-sqlite/ecto_sqlite3/pull/49)
- Updated error message for OTP24 [#47](https://github.com/elixir-sqlite/ecto_sqlite3/pull/47)


## [0.5.7] - 2021-08-17
### Changed
- Prepared statements can now be released manually.
- Added ability to specify `:asc_nulls_last`, `:asc_nulls_first`, `:desc_nulls_last`, and `:desc_nulls_first`.

## [0.5.6] - 2021-07-02
### Fixed
- Fix double quote missing from sql query generation. [#39](https://github.com/elixir-sqlite/ecto_sqlite3/pull/39)


## [0.5.5] - 2021-04-19
### Added
- Add :check constraint column option.

### Fixed
- Fix "database is locked" issue by setting `journal_mode` at `storage_up` time.


## [0.5.4] - 2021-04-06
### Changed
- Upgrade `ecto_sql` dependency to `3.6.0``
- Removed old `Ecto.Adapters.SQLite3.Connection.insert/6` was replaced with `Ecto.Adapters.SQLite3.Connection.insert/7`.


## [0.5.3] - 2021-03-20
### Added
- Added `collate:` opts support to `:string` column type


## [0.5.1] - 2021-03-18
### Changed
- Updated exqlite to `0.5.0`
- Updated documentation
- Updated git repository url


## 0.5.0 - 2021-03-17
- Initial release.


[keepachangelog]: <https://keepachangelog.com/en/1.0.0/>
[semver]: <https://semver.org/spec/v2.0.0.html>
[Unreleased]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.7.0...HEAD
[0.7.1]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.7...v0.6.0
[0.5.7]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.1...v0.5.3
[0.5.1]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.0...v0.5.1
