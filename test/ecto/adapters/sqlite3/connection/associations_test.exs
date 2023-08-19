defmodule Ecto.Adapters.SQLite3.Connection.AssociationsTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema
  alias EctoSQLite3.Schemas.Schema2

  test "association join belongs_to" do
    query =
      Schema2
      |> join(:inner, [c], p in assoc(c, :post))
      |> select([], true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema2" AS s0 INNER JOIN "schema" AS s1 ON s1."x" = s0."z"| ==
             all(query)
  end

  test "association join has_many" do
    query =
      Schema
      |> join(:inner, [p], c in assoc(p, :comments))
      |> select([], true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 INNER JOIN "schema2" AS s1 ON s1."z" = s0."x"| ==
             all(query)
  end

  test "association join has_one" do
    query =
      Schema
      |> join(:inner, [p], pp in assoc(p, :permalink))
      |> select([], true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 INNER JOIN "schema3" AS s1 ON s1."id" = s0."y"| ==
             all(query)
  end
end
