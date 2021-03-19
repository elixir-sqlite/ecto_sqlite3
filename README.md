# Ecto SQLite3 Adapter

[![Build Status](https://github.com/elixir-sqlite/ecto_sqlite3/workflows/CI/badge.svg)](https://github.com/elixir-sqlite/ecto_sqlite3/actions)

An Ecto SQLite3 Adapter. Uses [Exqlite](https://github.com/elixir-sqlite/exqlite) as the driver to communicate with sqlite3.

## Caveats and limitations

See [Limitations](https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html#module-limitations) in Hexdocs.

## Installation

```elixir
defp deps do
  {:ecto_sqlite3, "~> 0.5.2"}
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
for [`Ecto.Adapters.SQLite`](https://hexdocs.pm/ecto_sqlite3/). It will have more information on what is configurable.

```elixir
config :my_app,
  ecto_repos: [MyApp.Repo]

config :my_app, MyApp.Repo,
  database: "path/to/my/database.db",
```
