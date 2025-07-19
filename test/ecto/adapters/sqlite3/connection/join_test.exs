defmodule Ecto.Adapters.SQLite3.Connection.JoinTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema
  alias EctoSQLite3.Schemas.Schema2

  test "join" do
    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 INNER JOIN "schema2" AS s1 ON s0."x" = s1."z"} ==
             all(query)

    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> join(:inner, [], Schema, on: true)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 INNER JOIN "schema2" AS s1 ON s0."x" = s1."z" } <>
             ~s{INNER JOIN "schema" AS s2 ON 1} == all(query)
  end

  test "join with hints are not supported" do
    assert_raise Ecto.QueryError, ~r/join hints are not supported by SQLite3/, fn ->
      Schema
      |> join(:inner, [p], q in Schema2,
        hints: ["USE INDEX FOO", "USE INDEX BAR"],
        on: true
      )
      |> select([], true)
      |> plan()
      |> all()
    end
  end

  test "join with nothing bound" do
    query =
      Schema
      |> join(:inner, [], q in Schema2, on: q.z == q.z)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 } <>
             ~s{INNER JOIN "schema2" AS s1 ON s1."z" = s1."z"} == all(query)
  end

  test "join without schema" do
    query =
      "posts"
      |> join(:inner, [p], q in "comments", on: p.x == q.z)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "posts" AS p0 } <>
             ~s{INNER JOIN "comments" AS c1 ON p0."x" = c1."z"} == all(query)
  end

  test "join with subquery" do
    posts =
      subquery("posts" |> where(title: ^"hello") |> select([r], %{x: r.x, y: r.y}))

    query =
      "comments"
      |> join(:inner, [c], p in subquery(posts), on: true)
      |> select([_, p], p.x)
      |> plan()

    assert ~s{SELECT s1."x" FROM "comments" AS c0 } <>
             ~s{INNER JOIN (} <>
             ~s{SELECT sp0."x" AS "x", sp0."y" AS "y" FROM "posts" AS sp0 WHERE (sp0."title" = ?)} <>
             ~s{) AS s1 ON 1} == all(query)

    posts =
      "posts"
      |> where(title: ^"hello")
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()

    query =
      "comments"
      |> join(:inner, [c], p in subquery(posts), on: true)
      |> select([_, p], p)
      |> plan()

    assert ~s{SELECT s1."x", s1."z" FROM "comments" AS c0 } <>
             ~s{INNER JOIN (} <>
             ~s{SELECT sp0."x" AS "x", sp0."y" AS "z" FROM "posts" AS sp0 WHERE (sp0."title" = ?)} <>
             ~s{) AS s1 ON 1} == all(query)

    posts =
      "posts"
      |> where(title: parent_as(:comment).subtitle)
      |> select([r], r.title)
      |> subquery()

    query =
      "comments"
      |> from(as: :comment)
      |> join(:inner, [c], p in subquery(posts), on: true)
      |> select([_, p], p)
      |> plan()

    assert ~s{SELECT s1."title" FROM "comments" AS c0 } <>
             ~s{INNER JOIN (} <>
             ~s{SELECT sp0."title" AS "title" FROM "posts" AS sp0 WHERE (sp0."title" = c0."subtitle")} <>
             ~s{) AS s1 ON 1} == all(query)
  end

  test "join with prefix is not supported" do
    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> select([], true)
      |> Map.put(:prefix, "prefix")
      |> plan()
      |> all()
    end

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      Schema
      |> from(prefix: "first")
      |> join(:inner, [p], q in Schema2, on: p.x == q.z, prefix: "second")
      |> select([], true)
      |> Map.put(:prefix, "prefix")
      |> plan()
      |> all()
    end
  end

  test "join with values" do
    rows = [%{x: 1, y: 1}, %{x: 2, y: 2}]
    types = %{x: :integer, y: :integer}

    # Seeding rand ensures we get temp_78027 as the CTE name
    :rand.seed(:exsss, {1, 2, 3})

    query =
      Schema
      |> join(
        :inner,
        [p],
        q in values(rows, types),
        on: [x: p.x(), y: p.y()]
      )
      |> select([p, q], {p.id, q.x})
      |> plan()

    assert ~s{SELECT s0."id", v1."x" FROM "schema" AS s0 } <>
             ~s{INNER JOIN (WITH temp_78027(y, x) AS (VALUES ($1,$2),($3,$4)) SELECT * FROM temp_78027) AS v1 } <>
             ~s{ON (v1."x" = s0."x") AND (v1."y" = s0."y")} ==
             all(query)
  end

  test "join with fragment" do
    query =
      Schema
      |> join(
        :inner,
        [p],
        q in fragment(
          "SELECT * FROM schema2 AS s2 WHERE s2.id = ? AND s2.field = ?",
          p.x,
          ^10
        ),
        on: true
      )
      |> select([p], {p.id, ^0})
      |> where([p], p.id > 0 and p.id < ^100)
      |> plan()

    assert ~s{SELECT s0."id", ? FROM "schema" AS s0 INNER JOIN } <>
             ~s{(SELECT * FROM schema2 AS s2 WHERE s2.id = s0."x" AND s2.field = ?) AS f1 ON 1 } <>
             ~s{WHERE ((s0."id" > 0) AND (s0."id" < ?))} == all(query)
  end

  test "join with fragment and on defined" do
    query =
      Schema
      |> join(:inner, [p], q in fragment("SELECT * FROM schema2"), on: q.id == p.id)
      |> select([p], {p.id, ^0})
      |> plan()

    assert ~s{SELECT s0."id", ? FROM "schema" AS s0 INNER JOIN } <>
             ~s{(SELECT * FROM schema2) AS f1 ON f1."id" = s0."id"} == all(query)
  end

  test "join with query interpolation" do
    inner = Ecto.Queryable.to_query(Schema2)

    query =
      from(p in Schema)
      |> join(:left, [p], c in ^inner, on: true)
      |> select([p, c], {p.id, c.id})
      |> plan()

    assert ~s{SELECT s0."id", s1."id" FROM "schema" AS s0 } <>
             ~s{LEFT OUTER JOIN "schema2" AS s1 ON 1} == all(query)
  end

  test "lateral join with fragment is not supported" do
    assert_raise Ecto.QueryError, fn ->
      Schema
      |> join(
        :inner_lateral,
        [p],
        q in fragment(
          "SELECT * FROM schema2 AS s2 WHERE s2.id = ? AND s2.field = ?",
          p.x,
          ^10
        ),
        on: true
      )
      |> select([p, q], {p.id, q.z})
      |> where([p], p.id > 0 and p.id < ^100)
      |> plan()
      |> all()
    end
  end

  test "cross lateral join with fragment is not supported" do
    assert_raise Ecto.QueryError, fn ->
      Schema
      |> join(
        :cross_lateral,
        [p],
        q in fragment(
          "SELECT * FROM schema2 AS s2 WHERE s2.id = ? AND s2.field = ?",
          p.x,
          ^10
        )
      )
      |> select([p, q], {p.id, q.z})
      |> where([p], p.id > 0 and p.id < ^100)
      |> plan()
      |> all()
    end
  end

  test "cross join" do
    query =
      from(p in Schema)
      |> join(:cross, [p], c in Schema2)
      |> select([p, c], {p.id, c.id})
      |> plan()

    assert ~s{SELECT s0."id", s1."id" FROM "schema" AS s0 } <>
             ~s{CROSS JOIN "schema2" AS s1} == all(query)
  end

  test "cross join with fragment" do
    query =
      from(p in Schema)
      |> join(:cross, [p], fragment("json_each(?)", p.j))
      |> select([p], {p.id})
      |> plan()

    assert ~s{SELECT s0."id" FROM "schema" AS s0 } <>
             ~s{CROSS JOIN json_each(s0."j") AS f1} == all(query)
  end

  test "join from nested selects produces correct bindings" do
    query = from(p in Schema, join: c in Schema2, on: true)
    query = from(p in query, join: c in Schema2, on: true, select: {p.id, c.id})
    query = plan(query)

    assert ~s{SELECT s0."id", s2."id" FROM "schema" AS s0 } <>
             ~s{INNER JOIN "schema2" AS s1 ON 1 } <>
             ~s{INNER JOIN "schema2" AS s2 ON 1} == all(query)
  end

  describe "query interpolation parameters" do
    test "self join on subquery" do
      subquery = select(Schema, [r], %{x: r.x, y: r.y})

      query =
        subquery
        |> join(:inner, [c], p in subquery(subquery), on: true)
        |> plan()

      assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0 INNER JOIN } <>
               ~s{(SELECT ss0."x" AS "x", ss0."y" AS "y" FROM "schema" AS ss0) } <>
               ~s{AS s1 ON 1} == all(query)
    end

    test "self join on subquery with fragment" do
      subquery = select(Schema, [r], %{string: fragment("downcase(?)", ^"string")})

      query =
        subquery
        |> join(:inner, [c], p in subquery(subquery), on: true)
        |> plan()

      assert ~s{SELECT downcase(?) FROM "schema" AS s0 INNER JOIN } <>
               ~s{(SELECT downcase(?) AS "string" FROM "schema" AS ss0) } <>
               ~s{AS s1 ON 1} == all(query)
    end

    test "join on subquery with simple select" do
      subquery = select(Schema, [r], %{x: ^999, w: ^888})

      query =
        Schema
        |> select([r], %{y: ^666})
        |> join(:inner, [c], p in subquery(subquery), on: true)
        |> where([a, b], a.x == ^111)
        |> plan()

      assert all(query) ==
               ~s{SELECT ? FROM "schema" AS s0 INNER JOIN } <>
                 ~s{(SELECT ? AS "x", ? AS "w" FROM "schema" AS ss0) AS s1 ON 1 } <>
                 ~s{WHERE (s0."x" = ?)}
    end
  end
end
