defmodule Exqlite.ConnectionTest do
  use ExUnit.Case

  alias Exqlite.Connection

  describe ".connect/1" do
    test "returns error when path is missing from options" do
      {:error, error} = Connection.connect([])

      assert error.message == ~s{You must provide a :database to the database. Example: connect(database: "./") or connect(database: :memory)}
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
      {:ok, state} = Connection.connect(database: Temp.path!())

      assert state.path
      assert state.db
    end
  end

  describe ".disconnect/2" do
    test "disconnects a database that was never connected" do
      conn = %Exqlite.Connection{db: nil, path: nil}

      assert :ok == Connection.disconnect(nil, conn)
    end

    test "disconnects a connected database" do
      {:ok, conn} = Connection.connect(database: :memory)

      assert :ok == Connection.disconnect(nil, conn)
    end
  end
end
