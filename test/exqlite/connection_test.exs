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

      :ok =
        Sqlite3.execute(db, "create table users (id integer primary key, name text)")

      :ok = Sqlite3.execute(db, "insert into users (id, name) values (1, 'Jim')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (2, 'Bob')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (3, 'Dave')")
      :ok = Sqlite3.execute(db, "insert into users (id, name) values (4, 'Steve')")
      Sqlite3.close(db)

      {:ok, conn} = Connection.connect(database: path)

      {:ok, _query, result, _conn} =
        %Query{statement: "select * from users where id < ?"}
        |> Connection.handle_execute([4], [], conn)

      assert result.command == :execute
      assert result.columns == [id: "INTEGER", name: "text"]
      assert result.rows == [[1, "Jim"], [2, "Bob"], [3, "Dave"]]

      File.rm(path)
    end
  end

  describe ".handle_prepare/3" do
    test "returns a prepared query" do
      {:ok, conn} = Connection.connect(database: :memory)

      {:ok, _query, _result, conn} =
        %Query{statement: "create table users (id integer primary key, name text)"}
        |> Connection.handle_execute([], [], conn)

      {:ok, query, conn} =
        %Query{statement: "select * from users where id < ?"}
        |> Connection.handle_prepare([], conn)

      assert conn
      assert query
      assert query.ref
      assert query.statement
    end

    test "users table does not exist" do
      {:ok, conn} = Connection.connect(database: :memory)

      {:error, error, _state} =
        %Query{statement: "select * from users where id < ?"}
        |> Connection.handle_prepare([], conn)

      assert error.message == "no such table: users"
    end
  end

  describe ".checkin/1" do
    test "checking in an idle connection" do
      {:ok, conn} = Connection.connect(database: :memory)
      conn = %{conn | status: :idle}

      {:ok, conn} = Connection.checkin(conn)

      assert conn.status == :idle
    end

    test "checking in a busy connection" do
      {:ok, conn} = Connection.connect(database: :memory)
      conn = %{conn | status: :busy}

      {:ok, conn} = Connection.checkin(conn)

      assert conn.status == :idle
    end
  end

  describe ".checkout/1" do
    test "checking out an idle connection" do
      {:ok, conn} = Connection.connect(database: :memory)

      {:ok, conn} = Connection.checkout(conn)
      assert conn.status == :busy
    end

    test "checking out a busy connection" do
      {:ok, conn} = Connection.connect(database: :memory)
      conn = %{conn | status: :busy}

      {:disconnect, error, _conn} = Connection.checkout(conn)

      assert error.message == "Database is busy"
    end
  end

  describe ".ping/1" do
    test "returns the state passed unchanged" do
      {:ok, conn} = Connection.connect(database: :memory)

      assert {:ok, conn} == Connection.ping(conn)
    end
  end
end
