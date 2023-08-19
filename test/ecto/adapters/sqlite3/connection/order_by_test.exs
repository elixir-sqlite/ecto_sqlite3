defmodule Ecto.Adapters.SQLite3.Connection.OrderByTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "default" do
    query =
      Schema
      |> order_by([r], r.x)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{ORDER BY s0."x"} == all(query)
  end

  test "two columns with default" do
    query =
      Schema
      |> order_by([r], [r.x, r.y])
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{ORDER BY s0."x", s0."y"} == all(query)
  end

  test "two columns with direction specified" do
    query =
      Schema
      |> order_by([r], asc: r.x, desc: r.y)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{ORDER BY s0."x", s0."y" DESC} == all(query)
  end

  test "two columns with null ordering" do
    query =
      Schema
      |> order_by([r], asc_nulls_first: r.x, desc_nulls_first: r.y)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{ORDER BY s0."x" ASC NULLS FIRST, s0."y" DESC NULLS FIRST} == all(query)

    query =
      Schema
      |> order_by([r], asc_nulls_last: r.x, desc_nulls_last: r.y)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{ORDER BY s0."x" ASC NULLS LAST, s0."y" DESC NULLS LAST} == all(query)
  end

  test "nothing specified" do
    query =
      Schema
      |> order_by([r], [])
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0} == all(query)
  end

  test "can reference the alias of a selected value with selected_as/1" do
    query =
      "schema"
      |> select([s], selected_as(s.x, :integer))
      |> order_by(selected_as(:integer))
      |> plan()

    assert ~s{SELECT s0."x" AS "integer" FROM "schema" AS s0 } <>
             ~s{ORDER BY "integer"} == all(query)

    query =
      "schema"
      |> select([s], selected_as(s.x, :integer))
      |> order_by(desc: selected_as(:integer))
      |> plan()

    assert ~s{SELECT s0."x" AS "integer" FROM "schema" AS s0 } <>
             ~s{ORDER BY "integer" DESC} == all(query)
  end

  test "with types" do
    query =
      "schema3"
      |> order_by([e], type(fragment("?", e.binary), ^:decimal))
      |> select(true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema3" AS s0 } <>
             ~s{ORDER BY CAST(s0."binary" AS REAL)} == all(query)
  end
end
