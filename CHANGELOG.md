# Changelog

All notable changes will be documented in this file.

The format is loosely based on [Keep a Changelog][keepachangelog], and this
project adheres to [Semantic Versioning][semver].

## Unreleased
- changed: Enable `AUTOINCREMENT` for `serial` and `bigserial`. [#98](https://github.com/elixir-sqlite/ecto_qlite3/pull/98)
- **breaking**: Add support for sqlite strict mode. [#97](https://github.com/elixir-sqlite/ecto_sqlite3/pull/97)

With sqlite strict mode support being added, the following field "types" were altered.

* `TEXT_DATETIME` => `TEXT`
* `TEXT_UUID` => `TEXT`: This is when `:binary_id_type` is `:string`
* `UUID` => `BLOB`: This is when `:binary_id_type` is `:binary`

This is a breaking change in the sense that rebuilding the schema from scratch will cause those columns to show up differently. Under the hood sqlite does not actually care.

We kept `TEXT_DATETIME` to satisfy the old Ecto2 implementation to keep backwards compatibility.


## v0.9.1 - 2022-12-21
- changed: Use `Connection.connect` instead of `Sqlite3.open`. [#96](https://github.com/elixir-sqlite/ecto_sqlite3/pull/96)

## v0.9.0 - 2022-11-30
- fixed: Added `dump_cmd/3`
- fixed: Added `query_many/4`

## v0.8.2 - 2022-10-06
- fixed: `exists()` expression building. [#92](https://github.com/elixir-sqlite/ecto_sqlite3/pull/92)

## v0.8.1 - 2022-08-30
- changed: Allow `FROM` hints to be used. [#88](https://github.com/elixir-sqlite/ecto_sqlite3/pull/88)

## v0.8.0 - 2022-08-04
- changed: Set minimum elixir version to `~> 1.11`
- added: Allow index hints on joins. [#83](https://github.com/elixir-sqlite/ecto_sqlite3/pull/83)
- added: Allow datetime type to be configurable. [#84](https://github.com/elixir-sqlite/ecto_sqlite3/pull/84)

## v0.7.7 - 2022-06-21
- fixed: issue with missing space in `EXPLAIN QUERY PLAN`. [#78](https://github.com/elixir-sqlite/ecto_sqlite3/pull/78)

## v0.7.6 - 2022-06-20
- changed: explain query to `EXPLAIN QUERY PLAN`. [#77](https://github.com/elixir-sqlite/ecto_sqlite3/pull/77)

## v0.7.5 - 2022-05-21
- fixed: generate `binary_id` values according to the `binary_id_type` config. [#72](https://github.com/elixir-sqlite/ecto_sqlite3/pull/72)

## v0.7.4 - 2022-03-16
- fixed: double encoding of a string when converting to json. [#65](https://github.com/elixir-sqlite/ecto_sqlite3/pull/65)

## v0.7.3 - 2022-01-21
- added: information to the help docs about utilizing `exqlite` with database encryption.
- changed: raise more meaningful error when an expression fails to match. Backported from [ecto_sql#362](https://github.com/elixir-ecto/ecto_sql/commit/93038c2cac16706b642121a5839d1068d5b45212).

## v0.7.2 - 2021-09-29
- added: `:time` decode support. [#58](https://github.com/elixir-sqlite/ecto_sqlite3/pull/58)

## v0.7.1 - 2021-08-30
- fixed: Backport of default drops to `:restrict` are now backwards compatible with older versions of `ecto_sql`. We don't really have support for `drop index ... cascade` as it is not in the grammer of sqlite.

## v0.7.0 - 2021-08-27
- changed: update dependencies to the latest.
- changed: drop support for OTP 20. It is not supported by `telemetry` and won't compile. For now we will just support Elixir 1.8 and OTP 21.

## v0.6.1 - 2021-08-27
- changed: UUID encoding for both `:binary_id` and `:uuid`/`Ecto.UUID` is now configurable
- changed: `:uuid`/`Ecto.UUID` is now encoded as a string by default

## v0.6.0 - 2021-08-25
- changed: `:utc_datetime` handling has been updated to completely remove the `Z` supplied and made to conform closer to what is done for Postgrex and MyXQL. [#49](https://github.com/elixir-sqlite/ecto_sqlite3/pull/49)
- changed: updated error message for OTP24 [#47](https://github.com/elixir-sqlite/ecto_sqlite3/pull/47)

## v0.5.7 - 2021-08-17
- changed: prepared statements can now be released manually.
- changed: added ability to specify `:asc_nulls_last`, `:asc_nulls_first`, `:desc_nulls_last`, and `:desc_nulls_first`.

## v0.5.6 - 2021-07-02
- fixed: double quote missing from sql query generation. [#39](https://github.com/elixir-sqlite/ecto_sqlite3/pull/39)

## v0.5.5 - 2021-04-19
- added: `:check` constraint column option.
- fixed: "database is locked" issue by setting `journal_mode` at `storage_up` time.

## v0.5.4 - 2021-04-06
- changed: upgrade `ecto_sql` dependency to `3.6.0``
- changed: removed old `Ecto.Adapters.SQLite3.Connection.insert/6` was replaced with `Ecto.Adapters.SQLite3.Connection.insert/7`.

## v0.5.3 - 2021-03-20
- added: `collate:` opts support to `:string` column type

## v0.5.1 - 2021-03-18
- changed: updated exqlite to `0.5.0`
- changed: updated documentation
- changed: updated git repository url

## v0.5.0 - 2021-03-17
- initial release.


[keepachangelog]: <https://keepachangelog.com/en/1.0.0/>
[semver]: <https://semver.org/spec/v2.0.0.html>
