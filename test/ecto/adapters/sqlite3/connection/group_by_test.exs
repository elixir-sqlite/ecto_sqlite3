defmodule Ecto.Adapters.SQLite3.Connection.GroupByTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "group_by can reference the alias of a selected value with selected_as/1" do
    query =
      "schema"
      |> select([s], selected_as(s.x, :integer))
      |> group_by(selected_as(:integer))
      |> plan()

    assert ~s{SELECT s0."x" AS "integer" } <>
             ~s{FROM "schema" AS s0 } <>
             ~s{GROUP BY "integer"} == all(query)
  end

  test "having" do
    query =
      Schema
      |> having([p], p.x == p.x)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 HAVING (s0."x" = s0."x")} == all(query)

    query =
      Schema
      |> having([p], p.x == p.x)
      |> having([p], p.y == p.y)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 HAVING (s0."x" = s0."x") AND (s0."y" = s0."y")} ==
             all(query)
  end

  test "or_having" do
    query =
      Schema
      |> or_having([p], p.x == p.x)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 HAVING (s0."x" = s0."x")} == all(query)

    query =
      Schema
      |> or_having([p], p.x == p.x)
      |> or_having([p], p.y == p.y)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 HAVING (s0."x" = s0."x") OR (s0."y" = s0."y")} ==
             all(query)
  end

  test "group by" do
    query =
      Schema
      |> group_by([r], r.x)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY s0."x"} == all(query)

    query =
      Schema
      |> group_by([r], 2)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY 2} == all(query)

    query =
      Schema
      |> group_by([r], [r.x, r.y])
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY s0."x", s0."y"} == all(query)

    query =
      Schema
      |> group_by([r], [])
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0} == all(query)
  end
end
