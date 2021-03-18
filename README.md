# Ecto SQLite3 Adapter

[![Build Status](https://github.com/elixir-sqlite/ecto_sqlite3/workflows/CI/badge.svg)](https://github.com/elixir-sqlite/ecto_sqlite3/actions)

An Ecto SQLite3 Adapter.


## Caveats

* Prepared statements are not cached.
* Prepared statements are not immutable. You must be careful when manipulating
  statements and binding values to statements. Do not try to manipulate the
  statements concurrently. Keep it isolated to one process.
* Adding a `CHECK` constraint is not supported by the Ecto adapter. This is due
  to how Ecto handles specifying constraints. In SQLite you must specify the
  `CHECK` on creation.
* All native calls are run through the Dirty NIF scheduler.
* Datetimes are stored without offsets. This is due to how SQLite3 handles date
  and times. If you would like to store a timezone, you will need to create a
  second column somewhere storing the timezone name and shifting it when you
  get it from the database. This is more reliable than storing the offset as
  `+03:00` as it does not respect daylight savings time.


## Installation

```elixir
defp deps do
  {:ecto_sqlite3, "~> 0.5.0"}
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
for `SQLite3.Connection.connect/1`. It will have more information on what is
configurable.

```elixir
config :my_app,
  ecto_repos: [MyApp.Repo]

config :my_app, MyApp.Repo,
  database: "path/to/my/database.db",
  show_sensitive_data_on_connection_error: false,
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 1
```


### Note

* Pool size is set to `1` but can be increased to `4`. When set to `10` there
  was a lot of database busy errors. Currently this is a known issue and is
  being looked in to.

* Cache size is a negative number because that is how SQLite3 defines the cache
  size in kilobytes. If you make it positive, that is the number of pages in
  memory to use. Both have their pros and cons. Check the documentation out for
  [SQLite3][pragma].

* Uses [Exqlite][exqlite] as the driver to communicate with sqlite3.

## Contributing

Feel free to check the project out and submit pull requests.

[pragma]: <https://www.sqlite.org/pragma.html>
[exqlite]: <https://github.com/warmwaffles/exqlite>
