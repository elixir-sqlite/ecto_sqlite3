defmodule Ecto.Adapters.SQLite3.TestHelpers do
  @moduledoc """
  These are helpers that are useful in the `Connection` related tests.
  """

  alias Ecto.Adapter.Queryable
  alias Ecto.Adapters.SQLite3.Connection

  def plan(query, operation \\ :all) do
    {query, _cast_params, _dump_params} =
      Queryable.plan_query(operation, Ecto.Adapters.SQLite3, query)

    query
  end

  def all(query) do
    query
    |> Connection.all()
    |> IO.iodata_to_binary()
  end

  def update_all(query) do
    query
    |> Connection.update_all()
    |> IO.iodata_to_binary()
  end

  def delete_all(query) do
    query
    |> Connection.delete_all()
    |> IO.iodata_to_binary()
  end

  def execute_ddl(query) do
    query
    |> Connection.execute_ddl()
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  def insert(prefx, table, header, rows, on_conflict, returning, placeholders \\ []) do
    IO.iodata_to_binary(
      Connection.insert(
        prefx,
        table,
        header,
        rows,
        on_conflict,
        returning,
        placeholders
      )
    )
  end

  def update(prefx, table, fields, filter, returning) do
    IO.iodata_to_binary(Connection.update(prefx, table, fields, filter, returning))
  end

  def delete(prefx, table, filter, returning) do
    IO.iodata_to_binary(Connection.delete(prefx, table, filter, returning))
  end

  def remove_newlines(string) do
    string
    |> String.trim()
    |> String.replace("\n", " ")
  end
end
