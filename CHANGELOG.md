# Changelog

All notable changes will be documented in this file.

The format is based on [Keep a Changelog][keepachangelog], and this project
adheres to [Semantic Versioning][semver].

## [0.5.5] - Unreleased
- Fix "database is locked" issue by setting `journal_mode` at `storage_up` time.
- Add :check constraint column option.


## [0.5.4] - 2021-04-06
- Upgrade `ecto_sql` dependency to 3.6.0
- Removed old `Ecto.Adapters.SQLite3.Connection.insert/6` was replaced with
  `Ecto.Adapters.SQLite3.Connection.insert/7`.


## [0.5.3] - 2021-03-20
- Added `collate:` opts support to `:string` column type


## [0.5.1] - 2021-03-18
- Updated exqlite to 0.5.0
- Updated documentation
- Updated git repository url


## 0.5.0 - 2021-03-17
- Initial release.


[keepachangelog]: <https://keepachangelog.com/en/1.0.0/>
[semver]: <https://semver.org/spec/v2.0.0.html>
[0.5.4]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.1...v0.5.3
[0.5.1]: https://github.com/elixir-sqlite/ecto_sqlite3/compare/v0.5.0...v0.5.1
