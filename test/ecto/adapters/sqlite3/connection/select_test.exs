defmodule Ecto.Adapters.SQLite3.Connection.SelectTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "select" do
    query =
      Schema
      |> select([r], {r.x, r.y})
      |> plan()

    assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0} == all(query)

    query =
      Schema
      |> select([r], [r.x, r.y])
      |> plan()

    assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0} == all(query)

    query =
      Schema
      |> select([r], struct(r, [:x, :y]))
      |> plan()

    assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0} == all(query)
  end

  describe "distinct" do
    test "distinct true with binding" do
      query =
        Schema
        |> distinct([r], true)
        |> select([r], {r.x, r.y})
        |> plan()

      assert ~s{SELECT DISTINCT s0."x", s0."y" FROM "schema" AS s0} == all(query)
    end

    test "distinct false with binding" do
      query =
        Schema
        |> distinct([r], false)
        |> select([r], {r.x, r.y})
        |> plan()

      assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0} == all(query)
    end

    test "distinct true without binding" do
      query =
        Schema
        |> distinct(true)
        |> select([r], {r.x, r.y})
        |> plan()

      assert ~s{SELECT DISTINCT s0."x", s0."y" FROM "schema" AS s0} == all(query)
    end

    test "distinct false without binding" do
      query =
        Schema
        |> distinct(false)
        |> select([r], {r.x, r.y})
        |> plan()

      assert ~s{SELECT s0."x", s0."y" FROM "schema" AS s0} == all(query)
    end

    test "distinct with multiple columns is not supported" do
      assert_raise Ecto.QueryError,
                   ~r"DISTINCT with multiple columns is not supported by SQLite3",
                   fn ->
                     query =
                       Schema
                       |> distinct([r], [r.x, r.y])
                       |> select([r], {r.x, r.y})
                       |> plan()

                     all(query)
                   end
    end
  end

  test "where" do
    query =
      Schema
      |> where([r], r.x == 42)
      |> where([r], r.y != 43)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WHERE (s0."x" = 42) AND (s0."y" != 43)} == all(query)

    query =
      Schema
      |> where([r], {r.x, r.y} > {1, 2})
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WHERE ((s0."x",s0."y") > (1,2))} == all(query)
  end

  test "or_where" do
    query =
      Schema
      |> or_where([r], r.x == 42)
      |> or_where([r], r.y != 43)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WHERE (s0."x" = 42) OR (s0."y" != 43)} == all(query)

    query =
      Schema
      |> or_where([r], r.x == 42)
      |> or_where([r], r.y != 43)
      |> where([r], r.z == 44)
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WHERE ((s0."x" = 42) OR (s0."y" != 43)) AND (s0."z" = 44)} == all(query)
  end

  describe "fragments" do
    test "passing now for the fragment" do
      query =
        Schema
        |> select([r], fragment("now"))
        |> plan()

      assert ~s{SELECT now FROM "schema" AS s0} == all(query)
    end

    test "passing function with table" do
      query =
        Schema
        |> select([r], fragment("fun(?)", r))
        |> plan()

      assert ~s{SELECT fun(s0) FROM "schema" AS s0} == all(query)
    end

    test "passing function with column" do
      query =
        Schema
        |> select([r], fragment("downcase(?)", r.x))
        |> plan()

      assert ~s{SELECT downcase(s0."x") FROM "schema" AS s0} == all(query)
    end

    test "collating with literal" do
      query =
        Schema
        |> select([r], fragment("? COLLATE ?", r.x, literal(^"es_ES")))
        |> plan()

      assert ~s{SELECT s0."x" COLLATE "es_ES" FROM "schema" AS s0} == all(query)
    end

    test "fragment with a column and value specified" do
      value = 13

      query =
        Schema
        |> select([r], fragment("downcase(?, ?)", r.x, ^value))
        |> plan()

      assert ~s{SELECT downcase(s0."x", ?) FROM "schema" AS s0} == all(query)
    end

    test "does not support keywords in fragments" do
      assert_raise Ecto.QueryError, fn ->
        Schema
        |> select([], fragment(title: 2))
        |> plan()
        |> all()
      end
    end

    test "splicing" do
      query =
        Schema
        |> select([r], r.x)
        |> where([r], fragment("? in (?,?,?)", r.x, ^1, splice(^[2, 3, 4]), ^5))
        |> plan()

      assert all(query) ==
               ~s{SELECT s0."x" FROM "schema" AS s0 WHERE (s0."x" in (?,?,?,?,?))}
    end
  end

  describe "literals" do
    test "translates true to 1" do
      query =
        "schema"
        |> where(foo: true)
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = 1)} == all(query)
    end

    test "translates false to 0" do
      query =
        "schema"
        |> where(foo: false)
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = 0)} == all(query)
    end

    test "binds string" do
      query =
        "schema"
        |> where(foo: "abc")
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = 'abc')} == all(query)
    end

    test "puts binary as hex literal" do
      query =
        "schema"
        |> where(foo: <<0, ?a, ?b, ?c>>)
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = x'00616263')} ==
               all(query)
    end

    test "puts integer" do
      query =
        "schema"
        |> where(foo: 123)
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = 123)} == all(query)
    end

    test "puts float as a REAL" do
      query =
        "schema"
        |> where(foo: 123.0)
        |> select([], true)
        |> plan()

      assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (s0."foo" = CAST(123.0 AS REAL))} ==
               all(query)
    end
  end

  test "aliasing a selected value with selected_as/2" do
    query =
      "schema"
      |> select([s], selected_as(s.x, :integer))
      |> plan()

    assert ~s{SELECT s0."x" AS "integer" FROM "schema" AS s0} == all(query)

    query =
      "schema"
      |> select([s], s.x |> coalesce(0) |> sum() |> selected_as(:integer))
      |> plan()

    assert ~s{SELECT sum(coalesce(s0."x", 0)) AS "integer" FROM "schema" AS s0} ==
             all(query)
  end

  test "is_nil" do
    query =
      Schema
      |> select([r], is_nil(r.x))
      |> plan()

    assert ~s{SELECT s0."x" IS NULL FROM "schema" AS s0} == all(query)
  end

  test "not is_nil" do
    query =
      Schema
      |> select([r], not is_nil(r.x))
      |> plan()

    assert ~s{SELECT NOT (s0."x" IS NULL) FROM "schema" AS s0} == all(query)
  end

  test "is_nil with comparison" do
    query =
      "schema"
      |> select([r], r.x == is_nil(r.y))
      |> plan()

    assert ~s{SELECT s0."x" = (s0."y" IS NULL) FROM "schema" AS s0} == all(query)
  end

  describe "casting" do
    test "as integer" do
      query =
        Schema
        |> select([t], type(t.x + t.y, :integer))
        |> plan()

      assert ~s{SELECT CAST(s0."x" + s0."y" AS INTEGER) FROM "schema" AS s0} ==
               all(query)
    end

    test "casting uuid" do
      query =
        Schema
        |> select([], type(^"601d74e4-a8d3-4b6e-8365-eddb4c893327", Ecto.UUID))
        |> plan()

      assert ~s{SELECT CAST(? AS TEXT) FROM "schema" AS s0} == all(query)
    end

    test "casting array of uuids" do
      query =
        Schema
        |> select(
          [],
          type(^["601d74e4-a8d3-4b6e-8365-eddb4c893327"], {:array, Ecto.UUID})
        )
        |> plan()

      assert ~s{SELECT CAST(? AS TEXT) FROM "schema" AS s0} == all(query)
    end
  end

  test "nested expressions" do
    z = 123

    query =
      from(r in Schema, [])
      |> select([r], (r.x > 0 and r.y > ^(-z)) or true)
      |> plan()

    assert ~s{SELECT ((s0."x" > 0) AND (s0."y" > ?)) OR 1 FROM "schema" AS s0} ==
             all(query)
  end

  describe "in expression" do
    test "empty array" do
      query =
        Schema
        |> select([e], 1 in [])
        |> plan()

      assert ~s{SELECT 0 FROM "schema" AS s0} == all(query)
    end

    test "empty array binded" do
      query =
        Schema
        |> select([e], 1 in ^[])
        |> plan()

      assert ~s{SELECT 0 FROM "schema" AS s0} == all(query)
    end

    test "array of integers" do
      query =
        Schema
        |> select([e], 1 in ^[1, 2, 3])
        |> plan()

      assert ~s{SELECT 1 IN (?,?,?) FROM "schema" AS s0} == all(query)
    end

    test "array of integers with one binded" do
      query =
        Schema
        |> select([e], 1 in [1, ^2, 3])
        |> plan()

      assert ~s{SELECT 1 IN (1,?,3) FROM "schema" AS s0} == all(query)
    end

    test "mixed select with `in`" do
      query =
        Schema
        |> select([e], e.x == ^0 or e.x in ^[1, 2, 3] or e.x == ^4)
        |> plan()

      assert ~s{SELECT (} <>
               ~s{(s0."x" = ?) OR s0."x" IN (?,?,?)} <>
               ~s{) OR (s0."x" = ?) } <>
               ~s{FROM "schema" AS s0} == all(query)
    end

    test "json each" do
      query =
        Schema
        |> select([e], e in [1, 2, 3])
        |> plan()

      assert all(query) ==
               ~s{SELECT s0 IN (SELECT value FROM JSON_EACH('[1,2,3]')) FROM "schema" AS s0}
    end

    test "in with column binding" do
      query =
        Schema
        |> select([e], 1 in [1, e.x, 3])
        |> plan()

      assert all(query) == ~s{SELECT 1 IN (1,s0."x",3) FROM "schema" AS s0}
    end

    test "with value in binded in and out" do
      query =
        Schema
        |> select([e], ^1 in [1, ^2, 3])
        |> plan()

      assert all(query) == ~s{SELECT ? IN (1,?,3) FROM "schema" AS s0}
    end
  end

  test "in subquery" do
    posts = subquery("posts" |> where(title: ^"hello") |> select([p], p.id))

    query =
      "comments"
      |> where([c], c.post_id in subquery(posts))
      |> select([c], c.x)
      |> plan()

    assert all(query) ==
             ~s{SELECT c0."x" FROM "comments" AS c0 } <>
               ~s{WHERE (c0."post_id" IN (SELECT sp0."id" FROM "posts" AS sp0 WHERE (sp0."title" = ?)))}

    posts =
      subquery(
        "posts"
        |> where(title: parent_as(:comment).subtitle)
        |> select([p], p.id)
      )

    query =
      "comments"
      |> from(as: :comment)
      |> where([c], c.post_id in subquery(posts))
      |> select([c], c.x)
      |> plan()

    assert ~s{SELECT c0."x" FROM "comments" AS c0 } <>
             ~s{WHERE (c0."post_id" IN (} <>
             ~s{SELECT sp0."id" FROM "posts" AS sp0 WHERE (sp0."title" = c0."subtitle")} <>
             ~s{))} == all(query)
  end

  describe "arrays" do
    test "array of integers fragment is not supported" do
      assert_raise Ecto.QueryError, fn ->
        Schema
        |> select([], fragment("?", [1, 2, 3]))
        |> plan()
        |> all()
      end
    end

    test "array of strings fragment is not supported" do
      assert_raise Ecto.QueryError, fn ->
        Schema
        |> select([], fragment("?", ~w(abc def)))
        |> plan()
        |> all()
      end
    end

    test "empty array is supported" do
      query =
        Schema
        |> where([s], s.w == [])
        |> select([s], s.w)
        |> plan()

      assert ~s{SELECT s0."w" FROM "schema" AS s0 WHERE (s0."w" = '[]')} == all(query)
    end
  end

  test "fragments and types" do
    query =
      plan(
        from(e in "schema",
          where:
            fragment(
              "extract(? from ?) = ?",
              ^"month",
              e.start_time,
              type(^"4", :integer)
            ),
          where:
            fragment(
              "extract(? from ?) = ?",
              ^"year",
              e.start_time,
              type(^"2015", :integer)
            ),
          select: true
        )
      )

    assert ~s{SELECT 1 FROM "schema" AS s0 } <>
             ~s{WHERE (extract(? from s0."start_time") = CAST(? AS INTEGER)) } <>
             ~s{AND (extract(? from s0."start_time") = CAST(? AS INTEGER))} ==
             all(query)
  end

  test "fragments allow ? to be escaped with backslash" do
    query =
      plan(
        from(e in "schema",
          where: fragment("? = \"query\\?\"", e.start_time),
          select: true
        )
      )

    assert ~s{SELECT 1 FROM "schema" AS s0 } <>
             ~s{WHERE (s0."start_time" = "query?")} == all(query)
  end

  describe "binary operations" do
    test "equals" do
      query =
        Schema
        |> select([r], r.x == 2)
        |> plan()

      assert ~s{SELECT s0."x" = 2 FROM "schema" AS s0} == all(query)
    end

    test "does not equal" do
      query =
        Schema
        |> select([r], r.x != 2)
        |> plan()

      assert ~s{SELECT s0."x" != 2 FROM "schema" AS s0} == all(query)
    end

    test "lte" do
      query =
        Schema
        |> select([r], r.x <= 2)
        |> plan()

      assert ~s{SELECT s0."x" <= 2 FROM "schema" AS s0} == all(query)
    end

    test "gte" do
      query =
        Schema
        |> select([r], r.x >= 2)
        |> plan()

      assert ~s{SELECT s0."x" >= 2 FROM "schema" AS s0} == all(query)
    end

    test "lt" do
      query =
        Schema
        |> select([r], r.x < 2)
        |> plan()

      assert ~s{SELECT s0."x" < 2 FROM "schema" AS s0} == all(query)
    end

    test "gt" do
      query =
        Schema
        |> select([r], r.x > 2)
        |> plan()

      assert ~s{SELECT s0."x" > 2 FROM "schema" AS s0} == all(query)
    end

    test "add" do
      query =
        Schema
        |> select([r], r.x + 2)
        |> plan()

      assert ~s{SELECT s0."x" + 2 FROM "schema" AS s0} == all(query)
    end

    test "subtract" do
      query =
        Schema
        |> select([r], r.x - 2)
        |> plan()

      assert ~s{SELECT s0."x" - 2 FROM "schema" AS s0} == all(query)
    end

    test "multiply" do
      query =
        Schema
        |> select([r], r.x * 2)
        |> plan()

      assert ~s{SELECT s0."x" * 2 FROM "schema" AS s0} == all(query)
    end

    test "divide" do
      query =
        Schema
        |> select([r], r.x / 2)
        |> plan()

      assert ~s{SELECT s0."x" / 2 FROM "schema" AS s0} == all(query)
    end
  end

  test "limit specified" do
    query =
      Schema
      |> limit([r], 3)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 LIMIT 3} == all(query)
  end

  test "offset specified" do
    query =
      Schema
      |> offset([r], 5)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 OFFSET 5} == all(query)
  end

  test "limit and offset specified" do
    query =
      Schema
      |> offset([r], 5)
      |> limit([r], 3)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 LIMIT 3 OFFSET 5} == all(query)
  end
end
