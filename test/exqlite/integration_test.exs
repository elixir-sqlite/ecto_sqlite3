defmodule Exqlite.IntegrationTest do
  use ExUnit.Case

  alias Exqlite.Connection
  alias Exqlite.Sqlite3

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
end
