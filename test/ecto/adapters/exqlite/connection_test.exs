defmodule Ecto.Adapters.Exqlite.ConnectionTest do
  use ExUnit.Case

  alias Ecto.Adapters.Exqlite.Connection
  alias Ecto.Adapters.Exqlite
  # alias Ecto.Migration.Table

  import Ecto.Query


  defmodule Schema do
    use Ecto.Schema

    schema "schema" do
      field :x, :integer
      field :y, :integer
      field :z, :integer
      field :meta, :map

      has_many :comments, Ecto.Adapters.Exqlite.Schema2,
        references: :x,
        foreign_key: :z
      has_one :permalink, Ecto.Adapters.Exqlite.Schema3,
        references: :y,
        foreign_key: :id
    end
  end

  defmodule Schema2 do
    use Ecto.Schema

    schema "schema2" do
      belongs_to :post, Ecto.Adapters.Exqlite.Schema,
        references: :x,
        foreign_key: :z
    end
  end

  defmodule Schema3 do
    use Ecto.Schema

    schema "schema3" do
      field :binary, :binary
    end
  end

  defp plan(query, operation \\ :all) do
    {query, _params} = Ecto.Adapter.Queryable.plan_query(operation, Exqlite, query)
    query
  end

  defp all(query) do
    query
    |> Connection.all()
    |> IO.iodata_to_binary()
  end

  defp update_all(query) do
    query
    |> Connection.update_all()
    |> IO.iodata_to_binary()
  end

  defp delete_all(query) do
    query
    |> Connection.delete_all()
    |> IO.iodata_to_binary()
  end

  defp execute_ddl(query) do
    query
    |> Connection.execute_ddl()
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp insert(prefix, table, header, rows, on_conflict, returning) do
    prefix
    |> Connection.insert(table, header, rows, on_conflict, returning, [])
    |> IO.iodata_to_binary()
  end

  defp update(prefix, table, fields, filter, returning) do
    prefix
    |> Connection.update(table, fields, filter, returning)
    |> IO.iodata_to_binary()
  end

  defp delete(prefix, table, filter, returning) do
    prefix
    |> Connection.delete(table, filter, returning)
    |> IO.iodata_to_binary()
  end

  test "from" do
    query = Schema |> select([r], r.x) |> plan()
    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}
  end

  test "ignores from with hints" do
    query = Schema |> from(hints: ["USE INDEX FOO", "USE INDEX BAR"]) |> select([r], r.x) |> plan()
    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}
  end

  test "from without schema" do
    query = "posts" |> select([r], r.x) |> plan()
    assert all(query) == ~s{SELECT p0.x FROM posts AS p0}

    query = "posts" |> select([r], fragment("?", r)) |> plan()
    assert all(query) == ~s{SELECT p0 FROM posts AS p0}

    query = "Posts" |> select([:x]) |> plan()
    assert all(query) == ~s{SELECT P0.x FROM Posts AS P0}

    query = "0posts" |> select([:x]) |> plan()
    assert all(query) == ~s{SELECT t0.x FROM 0posts AS t0}

    assert_raise Ecto.QueryError, ~r"SQLite3 does not support selecting all fields from posts without a schema", fn ->
      all from(p in "posts", select: p) |> plan()
    end
  end
end
