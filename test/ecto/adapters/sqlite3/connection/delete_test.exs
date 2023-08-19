defmodule Ecto.Adapters.SQLite3.DeleteTest do
  use ExUnit.Case, async: true

  import Ecto.Adapters.SQLite3.TestHelpers

  test "delete" do
    query = delete(nil, "schema", [x: 1, y: 2], [])
    assert query == ~s{DELETE FROM "schema" WHERE "x" = ? AND "y" = ?}
  end
end
