defmodule Ecto.Adapters.SQLite3.Connection.DatetimeAddTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  test "datetime_add" do
    query =
      "schema"
      |> where([s], datetime_add(s.foo, 1, "month") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%d %H:%M:%f000Z',s0.\"foo\",1 || ' month') AS TEXT) > s0."bar")} ==
             all(query)

    query =
      "schema"
      |> where([s], datetime_add(type(s.foo, :string), 1, "month") > s.bar)
      |> select([], true)
      |> plan()

    assert ~s{SELECT 1 FROM "schema" AS s0 WHERE (CAST (strftime('%Y-%m-%d %H:%M:%f000Z',CAST(s0.\"foo\" AS TEXT),1 || ' month') AS TEXT) > s0."bar")} ==
             all(query)
  end
end
