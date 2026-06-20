defmodule Ecto.Adapters.SQLite3.Connection.UpdateAllTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias Ecto.Adapter.Queryable
  alias EctoSQLite3.Schemas.Schema
  alias EctoSQLite3.Schemas.Schema2

  test "update all" do
    query =
      from(m in Schema)
      |> update([m], set: [x: 0])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = 0} == update_all(query)

    query =
      from(m in Schema)
      |> update([m], set: [x: 0], inc: [y: 1, z: -3])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET } <>
             ~s{"x" = 0, "y" = "y" + 1, "z" = "z" + -3} == update_all(query)

    query =
      from(e in Schema)
      |> where([e], e.x == 123)
      |> update([e], set: [x: 0])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = 0 } <>
             ~s{WHERE (s0."x" = 123)} == update_all(query)

    query =
      from(m in Schema)
      |> update([m], set: [x: ^0])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = ?} == update_all(query)

    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> update([_], set: [x: 0])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = 0 } <>
             ~s{FROM "schema2" AS s1 } <>
             ~s{WHERE (s0."x" = s1."z")} == update_all(query)

    query =
      from(e in Schema)
      |> where([e], e.x == 123)
      |> update([e], set: [x: 0])
      |> join(:inner, [e], q in Schema2, on: e.x == q.z)
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = 0 } <>
             ~s{FROM "schema2" AS s1 } <>
             ~s{WHERE (s0."x" = s1."z") AND (s0."x" = 123)} == update_all(query)
  end

  test "update all with returning" do
    query =
      from(m in Schema)
      |> update([m], set: [x: 0])
      |> select([m], m)
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = 0 } <>
             ~s{RETURNING "id", "x", "y", "z", "w", "meta"} == update_all(query)

    query =
      from(m in Schema, update: [set: [x: ^1]])
      |> where([m], m.x == ^2)
      |> select([m], m.x == ^3)
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET "x" = ? } <>
             ~s{WHERE (s0."x" = ?) } <>
             ~s{RETURNING "x" = ?} == update_all(query)
  end

  test "does not support push op" do
    assert_raise Ecto.QueryError, fn ->
      from(m in Schema)
      |> update([m], push: [w: 0])
      |> plan(:update_all)
      |> update_all()
    end
  end

  test "does not support pull op" do
    assert_raise Ecto.QueryError, fn ->
      from(m in Schema)
      |> update([m], pull: [w: 0])
      |> plan(:update_all)
      |> update_all()
    end
  end

  test "update all with subquery" do
    sub = from(p in Schema, where: p.x > ^10)

    query =
      Schema
      |> join(:inner, [p], p2 in subquery(sub), on: p.id == p2.id)
      |> update([_], set: [x: ^100])

    {planned_query, cast_params, dump_params} =
      Queryable.plan_query(:update_all, Ecto.Adapters.SQLite3, query)

    assert ~s{UPDATE "schema" AS s0 SET "x" = ? FROM } <>
             ~s{(SELECT ss0."id" AS "id", ss0."x" AS "x", ss0."y" AS "y", } <>
             ~s{ss0."z" AS "z", ss0."w" AS "w", ss0."meta" AS "meta" } <>
             ~s{FROM "schema" AS ss0 WHERE (ss0."x" > ?)) } <>
             ~s{AS s1 WHERE (s0."id" = s1."id")} == update_all(planned_query)

    assert cast_params == [100, 10]
    assert dump_params == [100, 10]
  end

  test "update all with prefix" do
    query =
      from(m in Schema, update: [set: [x: 0]])
      |> Map.put(:prefix, "prefix")
      |> plan(:update_all)

    assert ~s{UPDATE prefix.schema AS s0 SET "x" = 0} == update_all(query)
  end

  test "update all with left join" do
    query =
      from(m in Schema)
      |> join(:inner, [m], x in assoc(m, :comments))
      |> join(:left, [m, x], p in assoc(m, :permalink))
      |> update([m, x, p], set: [w: m.list2])
      |> plan(:update_all)

    assert ~s{UPDATE "schema" AS s0 SET } <>
             ~s{"w" = s0."list2" } <>
             ~s{FROM "schema2" AS s1, "schema3" AS s2 } <>
             ~s{WHERE (s1."z" = s0."x") AND (s2."id" = s0."y")} == update_all(query)
  end
end
