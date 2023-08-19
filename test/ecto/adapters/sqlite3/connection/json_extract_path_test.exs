defmodule Ecto.Adapters.SQLite3.Connection.JsonExtractPathTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Adapters.SQLite3.TestHelpers

  alias EctoSQLite3.Schemas.Schema

  test "with array access" do
    query =
      Schema
      |> select([s], json_extract_path(s.meta, [0, 1]))
      |> plan()

    assert ~s|SELECT json_extract(s0.\"meta\", '$[0][1]') FROM "schema" AS s0| ==
             all(query)
  end

  test "with simple path" do
    query =
      Schema
      |> select([s], json_extract_path(s.meta, ["a", "b"]))
      |> plan()

    assert ~s|SELECT json_extract(s0.\"meta\", '$.a.b') FROM "schema" AS s0| ==
             all(query)
  end

  test "with a single quote in the key name" do
    query =
      Schema
      |> select([s], json_extract_path(s.meta, ["'a"]))
      |> plan()

    assert ~s|SELECT json_extract(s0.\"meta\", '$.''a') FROM "schema" AS s0| ==
             all(query)
  end

  test "with a double quote in the key name" do
    query =
      Schema
      |> select([s], json_extract_path(s.meta, ["\"a"]))
      |> plan()

    assert ~s|SELECT json_extract(s0.\"meta\", '$.\\\"a') FROM "schema" AS s0| ==
             all(query)
  end

  test "optimized selects with integer" do
    query =
      Schema
      |> where([s], s.meta["id"] == 123)
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0.\"meta\", '$.id') = 123)| ==
             all(query)
  end

  test "optimized selects with string" do
    query =
      Schema
      |> where([s], s.meta["id"] == "123")
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0."meta", '$.id') = '123')| ==
             all(query)
  end

  test "optimized deeply nested select" do
    query =
      Schema
      |> where([s], s.meta["tags"][0]["name"] == "123")
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0."meta", '$.tags[0].name') = '123')| ==
             all(query)
  end

  test "optimized array access" do
    query =
      Schema
      |> where([s], s.meta[0] == "123")
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0.\"meta\", '$[0]') = '123')| ==
             all(query)
  end

  test "optimized check for true" do
    query =
      Schema
      |> where([s], s.meta["enabled"] == true)
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0."meta", '$.enabled') = 1)| ==
             all(query)
  end

  test "optimized check for false" do
    query =
      Schema
      |> where([s], s.meta["extra"][0]["enabled"] == false)
      |> select(true)
      |> plan()

    assert ~s|SELECT 1 FROM "schema" AS s0 WHERE (json_extract(s0."meta", '$.extra[0].enabled') = 0)| ==
             all(query)
  end
end
