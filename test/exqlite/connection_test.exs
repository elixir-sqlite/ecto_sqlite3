defmodule Exqlite.ConnectionTest do
  use ExUnit.Case

  alias Exqlite.Connection

  describe ".connect/1" do
    test "returns error when path is missing from options" do
      {:error, error} = Connection.connect([])
      assert error.message == ~s{You must provide a :path to the database. Example: connect(path: "./") or connect(path: :memory)}
    end

    test "connects to an in memory database" do
      {:ok, state} = Connection.connect([path: ":memory:"])

      assert state.path == ":memory:"
      assert state.db
    end

    test "connects to a file" do
      {:ok, state} = Connection.connect([path: Temp.path!()])

      assert state.path
      assert state.db
    end
  end
end
