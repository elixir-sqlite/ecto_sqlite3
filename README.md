# Exqlite

An SQLite3 library. Similar to [esqlite][1] but there are some differences.

  * Prepared statements are not cached.
  * Prepared statements are not immutable. You must be careful when manipulating
    statements and binding values to statements.
  * All calls are run through the Dirty NIF scheduler.

## Installation

```elixir
defp deps do
  {:exqlite, "~> 0.1.0"}
end
```

## Usage

It's fairly straight forward.

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

## TODO

- [ ] An Ecto adapter

## Under The Hood

We are using the Dirty NIF scheduler to execute the sqlite calls. The rationale
behind this is that maintaining each sqlite's connection command pool is
complicated and error prone.

## Contributing

Feel free to check the project out and submit pull requests.

[1]: <https://github.com/mmzeeman/esqlite>
