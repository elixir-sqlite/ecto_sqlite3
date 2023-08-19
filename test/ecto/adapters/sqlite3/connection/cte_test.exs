defmodule Ecto.Adapters.SQLite3.Connection.CteTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema
  alias EctoSQLite3.Schemas.Schema2

  test "CTE" do
    initial_query =
      "categories"
      |> where([c], is_nil(c.parent_id))
      |> select([c], %{id: c.id, depth: fragment("1")})

    iteration_query =
      "categories"
      |> join(:inner, [c], t in "tree", on: t.id == c.parent_id)
      |> select([c, t], %{id: c.id, depth: fragment("? + 1", t.depth)})

    cte_query = initial_query |> union_all(^iteration_query)

    query =
      Schema
      |> recursive_ctes(true)
      |> with_cte("tree", as: ^cte_query)
      |> join(:inner, [r], t in "tree", on: t.id == r.category_id)
      |> select([r, t], %{x: r.x, category_id: t.id, depth: type(t.depth, :integer)})
      |> plan()

    assert all(query) ==
             ~s{WITH RECURSIVE "tree" AS } <>
               ~s{(SELECT sc0."id" AS "id", 1 AS "depth" FROM "categories" AS sc0 WHERE (sc0."parent_id" IS NULL) } <>
               ~s{UNION ALL } <>
               ~s{SELECT c0."id", t1."depth" + 1 FROM "categories" AS c0 } <>
               ~s{INNER JOIN "tree" AS t1 ON t1."id" = c0."parent_id") } <>
               ~s{SELECT s0."x", t1."id", CAST(t1."depth" AS INTEGER) } <>
               ~s{FROM "schema" AS s0 } <>
               ~s{INNER JOIN "tree" AS t1 ON t1."id" = s0."category_id"}
  end

  @raw_sql_cte """
  SELECT * FROM categories WHERE c.parent_id IS NULL
  UNION ALL
  SELECT * FROM categories AS c, category_tree AS ct WHERE ct.id = c.parent_id
  """

  test "reference CTE in union" do
    comments_scope_query =
      "comments"
      |> where([c], is_nil(c.deleted_at))
      |> select([c], %{entity_id: c.entity_id, text: c.text})

    posts_query =
      "posts"
      |> join(:inner, [p], c in "comments_scope", on: c.entity_id == p.guid)
      |> select([p, c], [p.title, c.text])

    videos_query =
      "videos"
      |> join(:inner, [v], c in "comments_scope", on: c.entity_id == v.guid)
      |> select([v, c], [v.title, c.text])

    query =
      posts_query
      |> union_all(^videos_query)
      |> with_cte("comments_scope", as: ^comments_scope_query)
      |> plan()

    assert all(query) ==
             ~s{WITH "comments_scope" AS (} <>
               ~s{SELECT sc0."entity_id" AS "entity_id", sc0."text" AS "text" } <>
               ~s{FROM "comments" AS sc0 WHERE (sc0."deleted_at" IS NULL)) } <>
               ~s{SELECT p0."title", c1."text" } <>
               ~s{FROM "posts" AS p0 } <>
               ~s{INNER JOIN "comments_scope" AS c1 ON c1."entity_id" = p0."guid" } <>
               ~s{UNION ALL } <>
               ~s{SELECT v0."title", c1."text" } <>
               ~s{FROM "videos" AS v0 } <>
               ~s{INNER JOIN "comments_scope" AS c1 ON c1."entity_id" = v0."guid"}
  end

  test "fragment CTE" do
    query =
      Schema
      |> recursive_ctes(true)
      |> with_cte("tree", as: fragment(@raw_sql_cte))
      |> join(:inner, [p], c in "tree", on: c.id == p.category_id)
      |> select([r], r.x)
      |> plan()

    assert all(query) ==
             ~s{WITH RECURSIVE "tree" AS (#{@raw_sql_cte}) } <>
               ~s{SELECT s0."x" } <>
               ~s{FROM "schema" AS s0 } <>
               ~s{INNER JOIN "tree" AS t1 ON t1."id" = s0."category_id"}
  end

  # TODO should error on lock
  test "CTE update_all" do
    cte_query =
      from(x in Schema,
        order_by: [asc: :id],
        limit: 10,
        lock: "FOR UPDATE SKIP LOCKED",
        select: %{id: x.id}
      )

    query =
      Schema
      |> with_cte("target_rows", as: ^cte_query)
      |> join(:inner, [row], target in "target_rows", on: target.id == row.id)
      |> select([r, t], r)
      |> update(set: [x: 123])
      |> plan(:update_all)

    assert update_all(query) ==
             ~s{WITH "target_rows" AS } <>
               ~s{(SELECT ss0."id" AS "id" FROM "schema" AS ss0 ORDER BY ss0."id" LIMIT 10) } <>
               ~s{UPDATE "schema" AS s0 } <>
               ~s{SET "x" = 123 } <>
               ~s{FROM "target_rows" AS t1 } <>
               ~s{WHERE (t1."id" = s0."id") } <>
               ~s{RETURNING "id", "x", "y", "z", "w", "meta"}
  end

  test "CTE delete_all" do
    cte_query =
      from(x in Schema,
        order_by: [asc: :id],
        limit: 10,
        inner_join: q in Schema2,
        on: x.x == q.z,
        select: %{id: x.id}
      )

    query =
      Schema
      |> with_cte("target_rows", as: ^cte_query)
      |> select([r, t], r)
      |> plan(:delete_all)

    assert delete_all(query) ==
             ~s{WITH "target_rows" AS } <>
               ~s{(SELECT ss0."id" AS "id" FROM "schema" AS ss0 INNER JOIN "schema2" AS ss1 ON ss0."x" = ss1."z" ORDER BY ss0."id" LIMIT 10) } <>
               ~s{DELETE FROM "schema" AS s0 } <>
               ~s{RETURNING "id", "x", "y", "z", "w", "meta"}
  end

  test "parent binding subquery and CTE" do
    initial_query =
      "categories"
      |> where([c], c.id == parent_as(:parent_category).id)
      |> select([:id, :parent_id])

    iteration_query =
      "categories"
      |> join(:inner, [c], t in "tree", on: t.parent_id == c.id)
      |> select([:id, :parent_id])

    cte_query = initial_query |> union_all(^iteration_query)

    breadcrumbs_query =
      "tree"
      |> recursive_ctes(true)
      |> with_cte("tree", as: ^cte_query)
      |> select([t], %{breadcrumbs: fragment("STRING_AGG(?, ' / ')", t.id)})

    query =
      from(c in "categories",
        as: :parent_category,
        left_lateral_join: b in subquery(breadcrumbs_query),
        on: true,
        select: %{id: c.id, breadcrumbs: b.breadcrumbs}
      )
      |> plan()

    assert_raise Ecto.QueryError,
                 ~r/join `:left_lateral` not supported by SQLite3/,
                 fn ->
                   all(query)
                 end
  end

  test "interpolated values" do
    cte1 =
      "schema1"
      |> select([m], %{id: m.id, smth: ^true})
      |> where([], fragment("?", ^1))

    union =
      "schema1"
      |> select([m], {m.id, ^true})
      |> where([], fragment("?", ^5))

    union_all =
      "schema2"
      |> select([m], {m.id, ^false})
      |> where([], fragment("?", ^6))

    query =
      "schema"
      |> with_cte("cte1", as: ^cte1)
      |> with_cte("cte2", as: fragment("SELECT * FROM schema WHERE ?", ^2))
      |> select([m], {m.id, ^true})
      |> join(:inner, [], Schema2, on: fragment("?", ^true))
      |> join(:inner, [], Schema2, on: fragment("?", ^false))
      |> where([], fragment("?", ^true))
      |> where([], fragment("?", ^false))
      |> having([], fragment("?", ^true))
      |> having([], fragment("?", ^false))
      |> group_by([], fragment("?", ^3))
      |> group_by([], fragment("?", ^4))
      |> union(^union)
      |> union_all(^union_all)
      |> order_by([], fragment("?", ^7))
      |> limit([], ^8)
      |> offset([], ^9)
      |> plan()

    result = """
    WITH "cte1" AS (SELECT ss0."id" AS "id", ? AS "smth" FROM "schema1" AS ss0 WHERE (?)), \
    "cte2" AS (SELECT * FROM schema WHERE ?) \
    SELECT s0."id", ? FROM "schema" AS s0 INNER JOIN "schema2" AS s1 ON ? \
    INNER JOIN "schema2" AS s2 ON ? WHERE (?) AND (?) \
    GROUP BY ?, ? HAVING (?) AND (?) \
    UNION SELECT s0."id", ? FROM "schema1" AS s0 WHERE (?) \
    UNION ALL SELECT s0."id", ? FROM "schema2" AS s0 WHERE (?) \
    ORDER BY ? LIMIT ? OFFSET ?\
    """

    assert all(query) == String.trim(result)
  end
end
