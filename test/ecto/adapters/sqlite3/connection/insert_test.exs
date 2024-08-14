defmodule Ecto.Adapters.SQLite3.Connection.InsertTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  test "insert" do
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:raise, [], []}, [:id])
    assert query == ~s{INSERT INTO "schema" ("x","y") VALUES (?,?) RETURNING "id"}

    assert_raise ArgumentError, fn ->
      insert(nil, "schema", [:x, :y], [[:x, :y], [nil, :z]], {:raise, [], []}, [:id])
    end

    assert_raise ArgumentError, fn ->
      insert(nil, "schema", [:x, :y], [[:x, :y], [nil, :z]], {:raise, [], []}, [:id], [
        1,
        2
      ])
    end

    query = insert(nil, "schema", [], [[]], {:raise, [], []}, [:id])
    assert query == ~s{INSERT INTO "schema" DEFAULT VALUES RETURNING "id"}

    query = insert(nil, "schema", [], [[]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO "schema" DEFAULT VALUES}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      insert("prefix", "schema", [], [[]], {:raise, [], []}, [])
    end

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:raise, [], []}, [:id])
    assert query == ~s{INSERT INTO "schema" ("x","y") VALUES (?,?) RETURNING "id"}

    assert_raise(
      ArgumentError,
      "Cell-wise default values are not supported on INSERT statements by SQLite3",
      fn ->
        insert(nil, "schema", [:x, :y], [[:x, :y], [nil, :z]], {:raise, [], []}, [:id])
      end
    )
  end

  test "insert with on conflict" do
    # For :nothing
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:nothing, [], []}, [])

    assert query ==
             ~s{INSERT INTO "schema" ("x","y") VALUES (?,?) ON CONFLICT DO NOTHING}

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:nothing, [], [:x, :y]}, [])

    assert query ==
             ~s{INSERT INTO "schema" ("x","y") VALUES (?,?) ON CONFLICT ("x","y") DO NOTHING}

    # For :update
    update = from("schema", update: [set: [z: "foo"]]) |> plan(:update_all)
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {update, [], [:x, :y]}, [:z])

    assert query ==
             ~s{INSERT INTO "schema" AS s0 ("x","y") VALUES (?,?) ON CONFLICT ("x","y") DO UPDATE SET "z" = 'foo' RETURNING "z"}

    # For :unsafe_fragment
    update = from("schema", update: [set: [z: "foo"]]) |> plan(:update_all)

    query =
      insert(
        nil,
        "schema",
        [:x, :y],
        [[:x, :y]],
        {update, [], {:unsafe_fragment, "foobar"}},
        [:z]
      )

    assert query ==
             ~s{INSERT INTO "schema" AS s0 ("x","y") VALUES (?,?) ON CONFLICT foobar DO UPDATE SET "z" = 'foo' RETURNING "z"}

    assert_raise ArgumentError, "Upsert in SQLite3 requires :conflict_target", fn ->
      conflict_target = []

      insert(
        nil,
        "schema",
        [:x, :y],
        [[:x, :y]],
        {:replace_all, [], conflict_target},
        []
      )
    end

    assert_raise ArgumentError,
                 "Upsert in SQLite3 does not support ON CONSTRAINT",
                 fn ->
                   insert(
                     nil,
                     "schema",
                     [:x, :y],
                     [[:x, :y]],
                     {:replace_all, [], {:constraint, :foo}},
                     []
                   )
                 end

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:replace_all, [], [:id]}, [])

    assert query ==
             """
             INSERT INTO "schema" ("x","y") \
             VALUES (?,?) \
             ON CONFLICT ("id") \
             DO UPDATE SET "x" = EXCLUDED."x","y" = EXCLUDED."y"\
             """
  end

  test "insert with query" do
    query = from("schema", select: [:id]) |> plan(:all)

    assert_raise ArgumentError, fn ->
      insert(
        nil,
        "schema",
        [:x, :y, :z],
        [[:x, {query, 3}, :z], [nil, {query, 2}, :z]],
        {:raise, [], []},
        [:id]
      )
    end
  end

  test "insert with query as rows" do
    query = from(s in "schema", select: %{foo: fragment("3"), bar: s.bar}) |> plan(:all)

    query = insert(nil, "schema", [:foo, :bar], query, {:raise, [], []}, [:foo])

    assert query == ~s{INSERT INTO "schema" ("foo","bar") SELECT 3, s0."bar" FROM "schema" AS s0 RETURNING "foo"}

    query =
      from(s in "schema", select: %{foo: fragment("3"), bar: s.bar}, where: true)
      |> plan(:all)

    query = insert(nil, "schema", [:foo, :bar], query, {:raise, [], []}, [:foo])

    assert query ==
             ~s{INSERT INTO "schema" ("foo","bar") SELECT 3, s0."bar" FROM "schema" AS s0 WHERE (1) RETURNING "foo"}
  end
end
