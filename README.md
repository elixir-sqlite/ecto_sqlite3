# Exqlite

An SQLite3 library with an Ecto adapter implementation.


## Caveats

* When using the Ecto adapter, all prepared statements are cached using an LRU
  cache.
* Prepared statements are not immutable. You must be careful when manipulating
  statements and binding values to statements. Do not try to manipulate the
  statements concurrently. Keep it isolated to one process.
* All native calls are run through the Dirty NIF scheduler.
* Datetimes are stored without offsets. This is due to how SQLite3 handles date
  and times. If you would like to store a timezone, you will need to create a
  second column somewhere storing the timezone name and shifting it when you
  get it from the database. This is more reliable than storing the offset as
  `+03:00` as it does not respect daylight savings time.
* `on_conflict: :ignore` may return an invalid / non-sensical primary key
  if a conflict was indeed hit. This is due to limitations around not being able
   to detect a conflict happened and thus using the last row insert id 
   which could be from any table.


## Installation

```elixir
defp deps do
  {:exqlite, "~> 0.1.0"}
end
```


## Usage Without Ecto

The `Exqlite.Sqlite3` module usage is fairly straight forward.

```elixir
# We'll just keep it in memory right now
{:ok, conn} = Exqlite.Sqlite3.open(":memory:")

# Create the table
:ok = Exqlite.Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)");

# Prepare a statement
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
:ok = Exqlite.Sqlite3.bind(conn, statement, ["Hello world"])

# Step is used to run statements
:done = Exqlite.Sqlite3.step(conn, statement)

# Prepare a select statement
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select id, stuff from test");

# Get the results
{:row, [1, "Hello world"]} = Exqlite.Sqlite3.step(conn, statement)

# No more results
:done = Exqlite.Sqlite3.step(conn, statement)
```


## Usage With Ecto

Define your repo similar to this.

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Exqlite
end
```

Configure your repository similar to the following. If you want to know more
about the possible options to pass the repository, checkout the documentation
for `Exqlite.Connection.connect/1`. It will have more information on what is
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
  [SQLite3][2].


## Why SQLite3

I needed an Ecto3 adapter to store time series data for a personal project. I
didn't want to go through the hassle of trying to setup a postgres database or
mysql database when I was just wanting to explore data ingestion and some map
reduce problems.

I also noticed that other SQLite3 implementations didn't really fit my needs. At
some point I also wanted to use this with a nerves project on an embedded device
that would be resiliant to power outages and still maintain some state that
`ets` can not afford.


## Under The Hood

We are using the Dirty NIF scheduler to execute the sqlite calls. The rationale
behind this is that maintaining each sqlite's connection command pool is
complicated and error prone.


## Contributing

Feel free to check the project out and submit pull requests.

[1]: <https://github.com/mmzeeman/esqlite>
[2]: <https://www.sqlite.org/pragma.html>
