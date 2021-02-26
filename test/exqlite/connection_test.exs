defmodule Exqlite.ConnectionTest do
  use ExUnit.Case

  alias Exqlite.Connection
  alias Exqlite.Query
  alias Exqlite.Sqlite3

  describe ".connect/1" do
    test "returns error when path is missing from options" do
      {:error, error} = Connection.connect([])

      assert error.message ==
               ~s{You must provide a :database to the database. Example: connect(database: "./") or connect(database: :memory)}
    end

    test "connects to an in memory database" do
      {:ok, state} = Connection.connect(database: ":memory:")

      assert state.path == ":memory:"
      assert state.db
    end

    test "connects to in memory when the memory atom is passed" do
      {:ok, state} = Connection.connect(database: :memory)

      assert state.path == ":memory:"
      assert state.db
    end

    test "connects to a file" do
      path = Temp.path!()
      {:ok, state} = Connection.connect(database: path)

      assert state.path == path
      assert state.db

      File.rm(path)
    end
  end

  describe ".disconnect/2" do
    test "disconnects a database that was never connected" do
      conn = %Connection{db: nil, path: nil}

      assert :ok == Connection.disconnect(nil, conn)
    end

    test "disconnects a connected database" do
      {:ok, conn} = Connection.connect(database: :memory)

      assert :ok == Connection.disconnect(nil, conn)
    end
  end

  describe ".handle_execute/4" do
    test "returns records" do
      path = Temp.path!()

      {:ok, db} = Sqlite3.open(path)
      :ok = Sqlite3.execute(db, "create table users (id integer primary key, name text)")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (1, 'Jim')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (2, 'Bob')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (3, 'Dave')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (4, 'Steve')")
      Sqlite3.close(db)

      {:ok, conn} = Connection.connect(database: path)
      {:ok, result, conn} =
        %Query{statement: "select * from users where id < ?"}
        |> Connection.handle_execute([4], [], conn)

      assert result.command == :execute
      assert result.columns == [id: "INTEGER", name: "text"]
      assert result.rows == [[1, "Jim"], [2, "Bob"], [3, "Dave"]]

      File.rm(path)
    end
  end
end
