defmodule Exqlite.Sqlite3Test do
  use ExUnit.Case

  alias Exqlite.Sqlite3

  describe ".open/1" do
    test "opens a database in memory" do
      {:ok, conn} = Sqlite3.open(":memory:")

      assert conn
    end

    test "opens a database on disk" do
      {:ok, path} = Temp.path()
      {:ok, conn} = Sqlite3.open(path)

      assert conn

      File.rm(path)
    end
  end

  describe ".close/2" do
    test "closes a database in memory" do
      {:ok, conn} = Sqlite3.open(":memory:")
      :ok = Sqlite3.close(conn)
    end
  end

  describe ".execute/2" do
    test "creates a table" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      :ok = Sqlite3.execute(conn, "insert into test (stuff) values ('This is a test')")
      {:ok, 1} = Sqlite3.last_insert_rowid(conn)
      {:ok, 1} = Sqlite3.changes(conn)
      :ok = Sqlite3.close(conn)
    end

    test "handles incorrect syntax" do
      {:ok, conn} = Sqlite3.open(":memory:")

      {:error, ~s|near "a": syntax error|} =
        Sqlite3.execute(
          conn,
          "create a dumb table test (id integer primary key, stuff text)"
        )

      {:ok, 0} = Sqlite3.changes(conn)
      :ok = Sqlite3.close(conn)
    end

    test "creates a virtual table with fts3" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create virtual table things using fts3(content text)")

      :ok =
        Sqlite3.execute(conn, "insert into things(content) VALUES ('this is content')")
    end

    test "creates a virtual table with fts4" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create virtual table things using fts4(content text)")

      :ok =
        Sqlite3.execute(conn, "insert into things(content) VALUES ('this is content')")
    end

    test "creates a virtual table with fts5" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok = Sqlite3.execute(conn, "create virtual table things using fts5(content)")

      :ok =
        Sqlite3.execute(conn, "insert into things(content) VALUES ('this is content')")
    end
  end

  describe ".prepare/3" do
    test "preparing a valid sql statement" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")

      assert statement
    end
  end

  describe ".bind/3" do
    test "binding values to a valid sql statement" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      :ok = Sqlite3.bind(conn, statement, ["testing"])
    end

    test "trying to bind with incorrect amount of arguments" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      {:error, :arguments_wrong_length} = Sqlite3.bind(conn, statement, [])
    end

    test "binds datetime value as string" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      :ok = Sqlite3.bind(conn, statement, [DateTime.utc_now()])
    end

    test "binds date value as string" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      :ok = Sqlite3.bind(conn, statement, [Date.utc_today()])
    end
  end

  describe ".columns/2" do
    test "returns the column definitions" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "select id, stuff from test")

      {:ok, columns} = Sqlite3.columns(conn, statement)

      assert ["id", "stuff"] == columns
    end
  end

  describe ".step/2" do
    test "returns results" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      :ok = Sqlite3.execute(conn, "insert into test (stuff) values ('This is a test')")
      {:ok, 1} = Sqlite3.last_insert_rowid(conn)
      :ok = Sqlite3.execute(conn, "insert into test (stuff) values ('Another test')")
      {:ok, 2} = Sqlite3.last_insert_rowid(conn)

      {:ok, statement} = Sqlite3.prepare(conn, "select id, stuff from test")

      {:row, columns} = Sqlite3.step(conn, statement)
      assert [1, "This is a test"] == columns
      {:row, columns} = Sqlite3.step(conn, statement)
      assert [2, "Another test"] == columns
      assert :done = Sqlite3.step(conn, statement)

      {:row, columns} = Sqlite3.step(conn, statement)
      assert [1, "This is a test"] == columns
      {:row, columns} = Sqlite3.step(conn, statement)
      assert [2, "Another test"] == columns
      assert :done = Sqlite3.step(conn, statement)
    end

    test "returns no results" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "select id, stuff from test")
      assert :done = Sqlite3.step(conn, statement)
    end

    test "works with insert" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      :ok = Sqlite3.bind(conn, statement, ["this is a test"])
      assert :done == Sqlite3.step(conn, statement)
    end
  end

  describe "working with prepared statements after close" do
    test "returns proper error" do
      {:ok, conn} = Sqlite3.open(":memory:")

      :ok =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      {:ok, statement} = Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
      :ok = Sqlite3.close(conn)
      :ok = Sqlite3.bind(conn, statement, ["this is a test"])

      {:error, message} =
        Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")

      assert message == "Sqlite3 was invoked incorrectly."

      assert :done == Sqlite3.step(conn, statement)
    end
  end
end
