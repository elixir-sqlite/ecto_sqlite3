defmodule Exqlite.IntegrationTest do
  use ExUnit.Case

  alias Exqlite.Connection
  alias Exqlite.Sqlite3
  alias Exqlite.Query

  test "simple prepare execute and close" do
    path = Temp.path!()
    {:ok, db} = Sqlite3.open(path)
    :ok = Sqlite3.execute(db, "create table test (id ingeger primary key, stuff text)")
    :ok = Sqlite3.close(db)

    {:ok, conn} = Connection.connect(database: path)

    {:ok, query, _} =
      %Exqlite.Query{statement: "SELECT * FROM test WHERE id = :id"}
      |> Connection.handle_prepare([2], conn)

    {:ok, _query, result, conn} = Connection.handle_execute(query, [2], [], conn)
    assert result

    {:ok, _, conn} = Connection.handle_close(query, [], conn)
    assert conn

    File.rm(path)
  end

  test "transaction handling with concurrent connections" do
    path = Temp.path!()

    {:ok, conn1} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory
      )

    {:ok, conn2} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory
      )

    {:ok, _result, conn1} = Connection.handle_begin([], conn1)
    assert conn1.transaction_status == :transaction
    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn1} = Connection.handle_execute(query, [], [], conn1)
    {:ok, _result, conn1} = Connection.handle_rollback([], conn1)
    assert conn1.transaction_status == :idle

    {:ok, _result, conn2} = Connection.handle_begin([], conn2)
    assert conn2.transaction_status == :transaction
    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn2} = Connection.handle_execute(query, [], [], conn2)
    {:ok, _result, conn2} = Connection.handle_rollback([], conn2)
    assert conn2.transaction_status == :idle

    File.rm(path)
  end

  test "handles busy correctly" do
    path = Temp.path!()

    {:ok, conn1} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory,
        busy_timeout: 0
      )

    {:ok, conn2} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory,
        busy_timeout: 0
      )

    {:ok, _result, conn1} = Connection.handle_begin([mode: :immediate], conn1)
    assert conn1.transaction_status == :transaction
    {:error, _err, conn2} = Connection.handle_begin([mode: :immediate], conn2)
    assert conn2.transaction_status == :idle
    {:ok, _result, conn1} = Connection.handle_commit([mode: :immediate], conn1)
    assert conn1.transaction_status == :idle
    {:ok, _result, conn2} = Connection.handle_begin([mode: :immediate], conn2)
    assert conn2.transaction_status == :transaction
    {:ok, _result, conn2} = Connection.handle_commit([mode: :immediate], conn2)
    assert conn2.transaction_status == :idle

    Connection.disconnect(nil, conn1)
    Connection.disconnect(nil, conn2)

    File.rm(path)
  end

  test "transaction with interleaved connections" do
    path = Temp.path!()

    {:ok, conn1} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory
      )

    {:ok, conn2} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory
      )

    {:ok, _result, conn1} = Connection.handle_begin([mode: :immediate], conn1)
    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn1} = Connection.handle_execute(query, [], [], conn1)

    # transaction overlap
    {:ok, _result, conn2} = Connection.handle_begin([], conn2)
    assert conn2.transaction_status == :transaction
    {:ok, _result, conn1} = Connection.handle_rollback([], conn1)
    assert conn1.transaction_status == :idle

    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn2} = Connection.handle_execute(query, [], [], conn2)
    {:ok, _result, conn2} = Connection.handle_rollback([], conn2)
    assert conn2.transaction_status == :idle

    Connection.disconnect(nil, conn1)
    Connection.disconnect(nil, conn2)

    File.rm(path)
  end

  test "transaction handling with single connection" do
    path = Temp.path!()

    {:ok, conn1} =
      Connection.connect(
        database: path,
        journal_mode: :wal,
        cache_size: -64000,
        temp_store: :memory
      )

    {:ok, _result, conn1} = Connection.handle_begin([], conn1)
    assert conn1.transaction_status == :transaction

    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn1} = Connection.handle_execute(query, [], [], conn1)
    {:ok, _result, conn1} = Connection.handle_rollback([], conn1)
    assert conn1.transaction_status == :idle

    {:ok, _result, conn1} = Connection.handle_begin([], conn1)
    assert conn1.transaction_status == :transaction

    query = %Query{statement: "create table foo(id integer, val integer)"}
    {:ok, _query, _result, conn1} = Connection.handle_execute(query, [], [], conn1)
    {:ok, _result, conn1} = Connection.handle_rollback([], conn1)
    assert conn1.transaction_status == :idle

    File.rm(path)
  end
end
