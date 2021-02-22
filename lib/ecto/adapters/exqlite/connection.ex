defmodule Ecto.Adapters.Exqlite.Connection do
  @behaviour Ecto.Adapters.SQL.Connection

  @impl true
  def child_spec(opts) do
    {:ok, _} = Application.ensure_all_started(:db_connection)
    DBConnection.child_spec(Exqlite.Connection, opts)
  end

  @impl true
  def query(conn, sql, params, opts) do
    opts = Keyword.put_new(opts, :query_type, :binary_then_text)

    query = %Exqlite.Query{name: Keyword.get(opts, :query_name, nil), statement: sql}

    conn
    |> DBConnection.prepare_execute(query, params, opts)
    |> case do
      {:ok, _query, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end
end
