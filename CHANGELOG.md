# Changelog

All notable changes will be documented in this file.

The format is loosely based on [Keep a Changelog][keepachangelog], and this
project adheres to [Semantic Versioning][semver].

## Unreleased

## v0.15.1

- fixed: Encode nil blobs. This was previously unhandled.

## v0.15.0

- fixed: Support `nil` decoding for `:decimal`.
- changed: Dropped support for Elixir v1.13.
- changed: Added Elixir v1.16 to CI build.
- changed: Bump minimum `exqlite` to `~ 0.19`.

## v0.14.0

- added: Support for encoding nil values in `:utc_datetime`, `:utc_datetime_usec`, `:naive_datetime`, and `:naive_datetime_usec` column dates.
- added: Allow subquery values in `insert_all`.

## v0.13.0

- added: Support fragment splicing.
- added: Support parent_as with combination queries.
- changed: Don't need to consider `{:maybe, type}`` when loading or dumping.
- changed: Handle nil values in dumpers and loaders.

## v0.12.0

- changed: raise if an in memory database is opened with a pool_size != 1
- added: support `{:unsafe_fragment, ".."}` as a conflict target.
- changed: Dropped support for Elixir `1.12`.
- changed: Dropped support for OTP 23.

## v0.11.0

- added: Support for DDL transactions.

## v0.10.4

- fixed: Handle binary uuid casting when `binary_id` is specified.

## v0.10.3

- fixed: Handle unique cosntraint error formats.
- changed: Updated depenendencies.

## v0.10.2

- added: Missing support for `Date` type.

## v0.10.1

- fixed: Ignore bad `init` file when using `dump_cmd/3`

## v0.10.0

- changed: Add support for Ecto `v3.10`
- changed: Bring SQLite closer to the Postgres adapter implementation
- changed: Enable `AUTOINCREMENT` for `serial` and `bigserial`.
- changed: **breaking** Add support for sqlite strict mode.

  With sqlite strict mode support being added, the following field "types" were altered.

  * `TEXT_DATETIME` => `TEXT`
  * `TEXT_UUID` => `TEXT`: This is when `:binary_id_type` is `:string`
  * `UUID` => `BLOB`: This is when `:binary_id_type` is `:binary`

  This is a breaking change in the sense that rebuilding the schema from scratch will cause those columns to show up differently. Under the hood sqlite does not actually care.

  We kept `TEXT_DATETIME` to satisfy the old Ecto2 implementation to keep backwards compatibility.

- changed: **breaking** Raise when table prefixes are used.

## v0.9.1
- changed: Use `Connection.connect` instead of `Sqlite3.open`.

## v0.9.0
- fixed: Added `dump_cmd/3`
- fixed: Added `query_many/4`

## v0.8.2
- fixed: `exists()` expression building.

## v0.8.1
- changed: Allow `FROM` hints to be used.

## v0.8.0
- changed: Set minimum elixir version to `~> 1.11`
- added: Allow index hints on joins.
- added: Allow datetime type to be configurable.

## v0.7.7
- fixed: issue with missing space in `EXPLAIN QUERY PLAN`.

## v0.7.6
- changed: explain query to `EXPLAIN QUERY PLAN`.

## v0.7.5
- fixed: generate `binary_id` values according to the `binary_id_type` config.

## v0.7.4
- fixed: double encoding of a string when converting to json.

## v0.7.3
- added: information to the help docs about utilizing `exqlite` with database encryption.
- changed: raise more meaningful error when an expression fails to match. Backported from [ecto_sql#362](https://github.com/elixir-ecto/ecto_sql/commit/93038c2cac16706b642121a5839d1068d5b45212).

## v0.7.2
- added: `:time` decode support.

## v0.7.1
- fixed: Backport of default drops to `:restrict` are now backwards compatible with older versions of `ecto_sql`. We don't really have support for `drop index ... cascade` as it is not in the grammer of sqlite.

## v0.7.0
- changed: update dependencies to the latest.
- changed: drop support for OTP 20. It is not supported by `telemetry` and won't compile. For now we will just support Elixir 1.8 and OTP 21.

## v0.6.1
- changed: UUID encoding for both `:binary_id` and `:uuid`/`Ecto.UUID` is now configurable
- changed: `:uuid`/`Ecto.UUID` is now encoded as a string by default

## v0.6.0
- changed: `:utc_datetime` handling has been updated to completely remove the `Z` supplied and made to conform closer to what is done for Postgrex and MyXQL. [#49](https://github.com/elixir-sqlite/ecto_sqlite3/pull/49)
- changed: updated error message for OTP24

## v0.5.7
- changed: prepared statements can now be released manually.
- changed: added ability to specify `:asc_nulls_last`, `:asc_nulls_first`, `:desc_nulls_last`, and `:desc_nulls_first`.

## v0.5.6
- fixed: double quote missing from sql query generation.

## v0.5.5
- added: `:check` constraint column option.
- fixed: "database is locked" issue by setting `journal_mode` at `storage_up` time.

## v0.5.4
- changed: upgrade `ecto_sql` dependency to `3.6.0``
- changed: removed old `Ecto.Adapters.SQLite3.Connection.insert/6` was replaced with `Ecto.Adapters.SQLite3.Connection.insert/7`.

## v0.5.3
- added: `collate:` opts support to `:string` column type

## v0.5.1
- changed: updated exqlite to `0.5.0`
- changed: updated documentation
- changed: updated git repository url

## v0.5.0
- initial release.


[keepachangelog]: <https://keepachangelog.com/en/1.0.0/>
[semver]: <https://semver.org/spec/v2.0.0.html>
