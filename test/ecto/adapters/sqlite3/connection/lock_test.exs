defmodule Ecto.Adapters.SQLite3.Connection.LockTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "locks are unsupported" do
    assert_raise ArgumentError, "locks are not supported by SQLite3", fn ->
      Schema
      |> lock("FOR SHARE NOWAIT")
      |> select([], true)
      |> plan()
      |> all()
    end

    assert_raise ArgumentError, "locks are not supported by SQLite3", fn ->
      Schema
      |> lock([p], fragment("UPDATE on ?", p))
      |> select([], true)
      |> plan()
      |> all()
    end
  end
end
