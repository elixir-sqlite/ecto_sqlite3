defmodule Ecto.Adapters.SQLite3.Connection.FromTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "using just a schema" do
    query =
      Schema
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0} == all(query)
  end

  test "from with hints" do
    query =
      Schema
      |> from(hints: "INDEXED BY FOO")
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 INDEXED BY FOO} == all(query)
  end

  describe "without schema" do
    test "a single column" do
      query =
        "posts"
        |> select([r], r.x)
        |> plan()

      assert ~s{SELECT p0."x" FROM "posts" AS p0} == all(query)
    end

    test "using a fragment" do
      query =
        "posts"
        |> select([r], fragment("?", r))
        |> plan()

      assert ~s{SELECT p0 FROM "posts" AS p0} == all(query)
    end

    test "uses string table name as is" do
      query =
        "Posts"
        |> select([:x])
        |> plan()

      assert ~s{SELECT P0."x" FROM "Posts" AS P0} == all(query)

      query =
        "0posts"
        |> select([:x])
        |> plan()

      assert ~s{SELECT t0."x" FROM "0posts" AS t0} == all(query)
    end

    test "raises when selecting all fields without a schema" do
      assert_raise Ecto.QueryError,
                   ~r"SQLite3 does not support selecting all fields from \"posts\" without a schema",
                   fn ->
                     all(from(p in "posts", select: p) |> plan())
                   end
    end
  end

  test "from with subquery" do
    query =
      "posts"
      |> select([r], %{x: r.x, y: r.y})
      |> subquery()
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM (} <>
             ~s{SELECT sp0."x" AS "x", sp0."y" AS "y" FROM "posts" AS sp0} <>
             ~s{) AS s0} == all(query)
  end

  test "select all columns from subquery" do
    query =
      "posts"
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()
      |> select([r], r)
      |> plan()

    assert ~s{SELECT s0."x", s0."z" FROM (} <>
             ~s{SELECT sp0."x" AS "x", sp0."y" AS "z" FROM "posts" AS sp0} <>
             ~s{) AS s0} ==
             all(query)
  end

  test "select all columns from deeply nested subquery" do
    query =
      "posts"
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()
      |> select([r], r)
      |> subquery()
      |> select([r], r)
      |> plan()

    assert ~s{SELECT s0."x", s0."z" FROM (} <>
             ~s{SELECT ss0."x" AS "x", ss0."z" AS "z" FROM (} <>
             ~s{SELECT ssp0."x" AS "x", ssp0."y" AS "z" FROM "posts" AS ssp0} <>
             ~s{) AS ss0} <>
             ~s{) AS s0} == all(query)
  end

  test "from with fragment" do
    query =
      from(f in fragment("select ? as x", ^"abc"))
      |> select([f], f.x)
      |> plan()

    assert ~s{SELECT f0."x" FROM (select ? as x) AS f0} == all(query)

    query =
      fragment("select ? as x", ^"abc")
      |> from()
      |> select(fragment("x"))
      |> plan()

    assert ~s{SELECT x FROM (select ? as x) AS f0} == all(query)

    query =
      from(f in fragment("select_rows(arg)"))
      |> select([f], f.x)
      |> plan()

    assert ~s{SELECT f0."x" FROM (select_rows(arg)) AS f0} == all(query)

    assert_raise Ecto.QueryError, ~r/^SQLite3 does not support/, fn ->
      from(f in fragment("select ? as x", ^"abc"))
      |> select([f], f)
      |> plan()
      |> all()
    end
  end
end
