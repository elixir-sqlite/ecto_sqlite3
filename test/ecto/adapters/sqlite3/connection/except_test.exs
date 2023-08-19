defmodule Ecto.Adapters.SQLite3.Connection.ExceptTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "except and except all" do
    base_query =
      Schema
      |> select([r], r.x)
      |> order_by(fragment("rand"))
      |> offset(10)
      |> limit(5)

    except_query1 =
      Schema
      |> select([r], r.y)
      |> order_by([r], r.y)
      |> offset(20)
      |> limit(40)

    except_query2 =
      Schema
      |> select([r], r.z)
      |> order_by([r], r.z)
      |> offset(30)
      |> limit(60)

    query =
      base_query
      |> except(^except_query1)
      |> except(^except_query2)
      |> plan()

    assert all(query) ==
             ~s{SELECT s0."x" FROM "schema" AS s0 } <>
               ~s{EXCEPT SELECT s0."y" FROM "schema" AS s0 ORDER BY s0."y" LIMIT 40 OFFSET 20 } <>
               ~s{EXCEPT SELECT s0."z" FROM "schema" AS s0 ORDER BY s0."z" LIMIT 60 OFFSET 30 } <>
               ~s{ORDER BY rand LIMIT 5 OFFSET 10}

    assert_raise Ecto.QueryError, fn ->
      base_query
      |> except_all(^except_query1)
      |> except_all(^except_query2)
      |> plan()
      |> all()
    end
  end
end
