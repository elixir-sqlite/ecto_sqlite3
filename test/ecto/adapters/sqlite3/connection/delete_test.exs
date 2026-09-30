defmodule Ecto.Adapters.SQLite3.DeleteTest do
  use ExUnit.Case, async: true

  import Ecto.Adapters.SQLite3.TestHelpers

  test "delete" do
    query = delete(nil, "schema", [x: 1, y: 2], [])
    assert query == ~s{DELETE FROM "schema" WHERE "x" = ? AND "y" = ?}

    query = delete("prefix", "schema", [x: 1, y: 2], [])
    assert query == ~s{DELETE FROM "prefix"."schema" WHERE "x" = ? AND "y" = ?}

    query = delete(nil, "schema", [x: nil, y: 2], [])
    assert query == ~s{DELETE FROM "schema" WHERE "x" IS NULL AND "y" = ?}
  end
end
