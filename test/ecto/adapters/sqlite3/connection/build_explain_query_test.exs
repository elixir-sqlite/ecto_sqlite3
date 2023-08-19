defmodule Ecto.Adapters.SQLite3.Connection.BuildExplainQueryTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQLite3.Connection

  test "build_explain_query" do
    assert Connection.build_explain_query("SELECT 1", :query_plan) ==
             "EXPLAIN QUERY PLAN SELECT 1"

    assert Connection.build_explain_query("SELECT 1", :instructions) ==
             "EXPLAIN SELECT 1"
  end
end
