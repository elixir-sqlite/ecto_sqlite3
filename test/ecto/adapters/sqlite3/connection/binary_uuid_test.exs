defmodule Ecto.Adapters.SQLite3.Connection.BinaryUUIDTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  setup_all do
    Application.put_env(:ecto_sqlite3, :uuid_type, :binary)
    Application.put_env(:ecto_sqlite3, :binary_id_type, :binary)

    on_exit(fn ->
      Application.put_env(:ecto_sqlite3, :uuid_type, :string)
      Application.put_env(:ecto_sqlite3, :binary_id_type, :string)
    end)
  end

  describe "select" do
    test "casting uuid" do
      query =
        Schema
        |> select([], type(^"601d74e4-a8d3-4b6e-8365-eddb4c893327", Ecto.UUID))
        |> plan()

      assert ~s{SELECT ? FROM "schema" AS s0} == all(query)
    end

    test "casting binary_ids" do
      query =
        Schema
        |> select([], type(^"601d74e4-a8d3-4b6e-8365-eddb4c893327", :binary_id))
        |> plan()

      assert ~s{SELECT ? FROM "schema" AS s0} == all(query)
    end
  end
end
