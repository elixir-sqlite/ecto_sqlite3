defmodule Ecto.Adapters.SQLite3.Connection.WindowingTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "one window" do
    query =
      Schema
      |> select([r], r.x)
      |> windows([r], w: [partition_by: r.x])
      |> plan

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WINDOW "w" AS (PARTITION BY s0."x")} == all(query)
  end

  test "two windows" do
    query =
      Schema
      |> select([r], r.x)
      |> windows([r], w1: [partition_by: r.x], w2: [partition_by: r.y])
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WINDOW "w1" AS (PARTITION BY s0."x"), } <>
             ~s{"w2" AS (PARTITION BY s0."y")} == all(query)
  end

  test "count over window" do
    query =
      Schema
      |> windows([r], w: [partition_by: r.x])
      |> select([r], count(r.x) |> over(:w))
      |> plan()

    assert ~s{SELECT count(s0."x") OVER "w" FROM "schema" AS s0 } <>
             ~s{WINDOW "w" AS (PARTITION BY s0."x")} == all(query)
  end

  test "count over all" do
    query =
      Schema
      |> select([r], count(r.x) |> over)
      |> plan()

    assert ~s{SELECT count(s0."x") OVER () FROM "schema" AS s0} == all(query)
  end

  test "row_number over all" do
    query =
      Schema
      |> select(row_number |> over)
      |> plan()

    assert ~s{SELECT row_number() OVER () FROM "schema" AS s0} == all(query)
  end

  test "nth_value over all" do
    query =
      Schema
      |> select([r], nth_value(r.x, 42) |> over)
      |> plan()

    assert ~s{SELECT nth_value(s0."x", 42) OVER () FROM "schema" AS s0} == all(query)
  end

  test "lag/2 over all" do
    query =
      Schema
      |> select([r], lag(r.x, 42) |> over)
      |> plan()

    assert ~s{SELECT lag(s0."x", 42) OVER () FROM "schema" AS s0} == all(query)
  end

  test "custom aggregation over all" do
    query =
      Schema
      |> select([r], fragment("custom_function(?)", r.x) |> over)
      |> plan()

    assert ~s{SELECT custom_function(s0."x") OVER () FROM "schema" AS s0} == all(query)
  end

  test "partition by and order by on window" do
    query =
      Schema
      |> windows([r], w: [partition_by: [r.x, r.z], order_by: r.x])
      |> select([r], r.x)
      |> plan()

    assert ~s{SELECT s0."x" FROM "schema" AS s0 } <>
             ~s{WINDOW "w" AS (} <>
             ~s{PARTITION BY s0."x", s0."z" } <>
             ~s{ORDER BY s0."x")} == all(query)
  end

  test "partition by one order by over" do
    query =
      Schema
      |> select([r], count(r.x) |> over(partition_by: [r.x, r.z], order_by: r.x))
      |> plan()

    assert ~s{SELECT count(s0."x") } <>
             ~s{OVER (PARTITION BY s0."x", s0."z" ORDER BY s0."x") } <>
             ~s{FROM "schema" AS s0} == all(query)
  end

  test "frame clause" do
    query =
      Schema
      |> select(
        [r],
        count(r.x)
        |> over(
          partition_by: [r.x, r.z],
          order_by: r.x,
          frame: fragment("ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING")
        )
      )
      |> plan()

    assert ~s{SELECT count(s0."x") } <>
             ~s{OVER (} <>
             ~s{PARTITION BY s0."x", s0."z" } <>
             ~s{ORDER BY s0."x" } <>
             ~s{ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING} <>
             ~s{) FROM "schema" AS s0} == all(query)
  end
end
