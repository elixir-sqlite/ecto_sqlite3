defmodule Ecto.Adapters.SQLite3.Connection.DatetimeAddTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  test "add a month" do
    query =
      "schema"
      |> where([s], datetime_add(s.foo, 1, "month") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%dT%H:%M:%f000Z',s0.\"foo\",1 || ' month') AS TEXT) > s0."bar")} ==
             all(query)
  end

  test "add a month with a string cast" do
    query =
      "schema"
      |> where([s], datetime_add(type(s.foo, :string), 1, "month") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%dT%H:%M:%f000Z',CAST(s0.\"foo\" AS TEXT),1 || ' month') AS TEXT) > s0."bar")} ==
             all(query)
  end

  test "parenthesizes compound day count" do
    query =
      "schema"
      |> where([s], datetime_add(s.foo, s.x + s.y, "day") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%dT%H:%M:%f000Z',s0.\"foo\",(s0.\"x\" + s0.\"y\") || ' day') AS TEXT) > s0."bar")} ==
             all(query)
  end

  test "parenthesizes compound week count" do
    query =
      "schema"
      |> where([s], datetime_add(s.foo, s.x + s.y, "week") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%dT%H:%M:%f000Z',s0.\"foo\",((s0.\"x\" + s0.\"y\") * 7) || ' days') AS TEXT) > s0."bar")} ==
             all(query)
  end

  test "parenthesizes compound millisecond count" do
    query =
      "schema"
      |> where([s], datetime_add(s.foo, s.x + s.y, "millisecond") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%dT%H:%M:%f000Z',s0.\"foo\",((s0.\"x\" + s0.\"y\") / 1000.0) || ' seconds') AS TEXT) > s0."bar")} ==
             all(query)
  end

  test "date_add parenthesizes compound day count" do
    query =
      "schema"
      |> where([s], date_add(s.foo, s.x + s.y, "day") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%d',s0.\"foo\",(s0.\"x\" + s0.\"y\") || ' day') AS TEXT) > s0."bar")} ==
             all(query)
  end
end
