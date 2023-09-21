defmodule Ecto.Adapters.SQLite3.Connection.UnionTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "union and union all" do
    base_query =
      Schema
      |> select([r], r.x)
      |> order_by(fragment("rand"))
      |> offset(10)
      |> limit(5)

    union_query1 =
      Schema
      |> select([r], r.y)
      |> order_by([r], r.y)
      |> offset(20)
      |> limit(40)

    union_query2 =
      Schema
      |> select([r], r.z)
      |> order_by([r], r.z)
      |> offset(30)
      |> limit(60)

    query =
      base_query
      |> union(^union_query1)
      |> union(^union_query2)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{UNION SELECT s0."y" FROM "schema" AS s0 ORDER BY s0."y" LIMIT 40 OFFSET 20 } <>
             ~s{UNION SELECT s0."z" FROM "schema" AS s0 ORDER BY s0."z" LIMIT 60 OFFSET 30 } <>
             ~s{ORDER BY rand LIMIT 5 OFFSET 10} == all(query)

    query =
      base_query
      |> union_all(^union_query1)
      |> union_all(^union_query2)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{UNION ALL SELECT s0."y" FROM "schema" AS s0 ORDER BY s0."y" LIMIT 40 OFFSET 20 } <>
             ~s{UNION ALL SELECT s0."z" FROM "schema" AS s0 ORDER BY s0."z" LIMIT 60 OFFSET 30 } <>
             ~s{ORDER BY rand LIMIT 5 OFFSET 10} == all(query)
  end

  test "parent binding subquery and combination" do
    right_query = from(c in "right_categories", where: c.id == parent_as(:c).id, select: c.id)
    left_query = from(c in "left_categories", where: c.id == parent_as(:c).id, select: c.id)
    union_query = union(left_query, ^right_query)
    query = from(c in "categories", as: :c, where: c.id in subquery(union_query), select: c.id) |> plan()

    assert all(query) ==
      ~s{SELECT c0."id" FROM "categories" AS c0 } <>
      ~s{WHERE (} <>
      ~s{c0."id" IN } <>
      ~s{(SELECT sl0."id" FROM "left_categories" AS sl0 WHERE (sl0."id" = c0."id") } <>
      ~s{UNION } <>
      ~s{SELECT sr0."id" FROM "right_categories" AS sr0 WHERE (sr0."id" = c0."id")))}
  end
end
