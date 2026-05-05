defmodule Ecto.Adapters.SQLite3.Connection.DeleteAllTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias Ecto.Queryable
  alias EctoSQLite3.Schemas.Schema
  alias EctoSQLite3.Schemas.Schema2

  test "delete all with only the schema" do
    query =
      Schema
      |> Queryable.to_query()
      |> plan()

    assert ~s{DELETE FROM "schema" AS s0} == delete_all(query)
  end

  test "delete all with filters" do
    query =
      from(e in Schema)
      |> where([e], e.x == 123)
      |> plan()

    assert ~s{DELETE FROM "schema" AS s0 WHERE (s0."x" = 123)} == delete_all(query)
  end

  test "join in a delete is not supported" do
    assert_raise ArgumentError, fn ->
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> plan()
      |> delete_all()
    end

    assert_raise ArgumentError, fn ->
      from(e in Schema)
      |> where([e], e.x == 123)
      |> join(:inner, [e], q in Schema2, on: e.x == q.z)
      |> plan()
      |> delete_all()
    end

    assert_raise ArgumentError, fn ->
      from(e in Schema,
        where: e.x == 123,
        join: assoc(e, :comments),
        join: assoc(e, :permalink)
      )
      |> plan()
      |> delete_all()
    end
  end

  test "delete all with returning" do
    query =
      Schema
      |> Queryable.to_query()
      |> select([m], m)
      |> plan()

    assert ~s{DELETE FROM "schema" AS s0 RETURNING "id", "x", "y", "z", "w", "meta"} ==
             delete_all(query)
  end

  test "delete all with prefix" do
    query =
      Schema
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert ~s{DELETE FROM prefix.schema AS s0} == delete_all(query)

    query =
      Schema
      |> from(prefix: "first")
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert ~s{DELETE FROM first.schema AS s0} == delete_all(query)
  end
end
