defmodule Ecto.Adapters.SQLite3.Connection.AggregatesTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "counts" do
    query =
      Schema
      |> select([r], count(r.x))
      |> plan()

    assert ~s{SELECT count(s0."x") FROM "schema" AS s0} == all(query)
  end

  test "raises when counting a source" do
    query =
      Schema
      |> select([r], count(r))
      |> plan()

    msg = ~r"The argument to `count/1` must be a column in SQLite3"

    assert_raise Ecto.QueryError, msg, fn ->
      all(query)
    end
  end

  test "distinct counts" do
    query =
      Schema
      |> select([r], count(r.x, :distinct))
      |> plan()

    assert ~s{SELECT count(distinct s0."x") FROM "schema" AS s0} == all(query)
  end

  test "allows naked count" do
    query =
      Schema
      |> select([r], count())
      |> plan()

    assert ~s{SELECT count(*) FROM "schema" AS s0} == all(query)
  end

  test "aggregate count with a filter" do
    query =
      Schema
      |> select([r], count(r.x) |> filter(r.x > 10))
      |> plan()

    assert ~s{SELECT count(s0."x") FILTER (WHERE s0."x" > 10) FROM "schema" AS s0} ==
             all(query)
  end

  test "aggregate count with a more complex filter" do
    query =
      Schema
      |> select([r], count(r.x) |> filter(r.x > 10 and r.x < 50))
      |> plan()

    assert ~s{SELECT count(s0."x") FILTER (WHERE (s0."x" > 10) AND (s0."x" < 50)) FROM "schema" AS s0} ==
             all(query)
  end

  test "aggregate naked count with a filter" do
    query =
      Schema
      |> select([r], count() |> filter(r.x > 10))
      |> plan()

    assert ~s{SELECT count(*) FILTER (WHERE s0."x" > 10) FROM "schema" AS s0} ==
             all(query)
  end
end
