# Ecto SQLite3 Adapter

[![Build Status](https://github.com/elixir-sqlite/ecto_sqlite3/workflows/CI/badge.svg)](https://github.com/elixir-sqlite/ecto_sqlite3/actions)
[![Hex Package](https://img.shields.io/hexpm/v/ecto_sqlite3.svg)](https://hex.pm/packages/ecto_sqlite3)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/ecto_sqlite3)

An Ecto SQLite3 Adapter. Uses [Exqlite](https://github.com/elixir-sqlite/exqlite)
as the driver to communicate with sqlite3.

## Caveats and limitations

See [Limitations](https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html#module-limitations-and-caveats)
in Hexdocs.

## Installation

```elixir
defp deps do
  [
    {:ecto_sqlite3, "~> 0.17"}
  ]
end
```

## Usage

Define your repo similar to this.

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.SQLite3
end
```

Configure your repository similar to the following. If you want to know more
about the possible options to pass the repository, checkout the documentation
for [`Ecto.Adapters.SQLite`](https://hexdocs.pm/ecto_sqlite3/). It will have
more information on what is configurable.

```elixir
config :my_app,
  ecto_repos: [MyApp.Repo]

config :my_app, MyApp.Repo,
  database: "path/to/my/database.db"
```

## Database Encryption

As of version 0.9, `exqlite` supports loading database engines at runtime rather than compiling `sqlite3.c` itself.
This can be used to support database level encryption via alternate engines such as [SQLCipher](https://www.zetetic.net/sqlcipher/design)
or the [Official SEE extension](https://www.sqlite.org/see/doc/trunk/www/readme.wiki). Once you have either of those projects installed
on your system, use the following environment variables during compilation:

```bash
# tell exqlite that we wish to use some other sqlite installation. this will prevent sqlite3.c and friends from compiling
export EXQLITE_USE_SYSTEM=1

# Tell exqlite where to find the `sqlite3.h` file
export EXQLITE_SYSTEM_CFLAGS=-I/usr/local/include/sqlcipher

# tell exqlite which sqlite implementation to use
export EXQLITE_SYSTEM_LDFLAGS=-L/usr/local/lib -lsqlcipher
```

Once you have `exqlite` configured, you can use the `:key` option in the database config to enable encryption:

```elixir
config :my_app, MyApp.Repo,
  database: "path/to/my/encrypted-database.db",
  key: "supersecret'
```

## Benchmarks

We have some benchmarks comparing it against the `MySQL` and `Postgres` adapters.

You can read more about those at [bench/README.md](bench/README.md).

## Running Tests

Running unit tests

```sh
mix test
```

Running integration tests

```sh
EXQLITE_INTEGRATION=true mix test
```
