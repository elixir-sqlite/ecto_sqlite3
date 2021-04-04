# Changelog

All notable changes will be documented in this file.

The format is based on [Keep a Changelog][keepachangelog], and this project
adheres to [Semantic Versioning][semver].

## [Unreleased]
- Upgrade `ecto_sql` dependency to 3.6.0
- Removed old `Ecto.Adapters.SQLite3.Connection.insert/6` was replaced with
  `Ecto.Adapters.SQLite3.Connection.insert/7`.

## [0.5.3] - 2021-03-20
- Added `collate:` opts support to `:string` column type

## [0.5.1] - 2021-03-18
- Updated exqlite to 0.5.0
- Updated documentation
- Updated git repository url

## [0.5.0] - 2021-03-17
- Initial release.

[keepachangelog]: <https://keepachangelog.com/en/1.0.0/>
[semver]: <https://semver.org/spec/v2.0.0.html>
