defmodule Exqlite.Stream do
  @moduledoc false
  defstruct [:conn, :query, :params, :options, max_rows: 500]
  @type t :: %Exqlite.Stream{}

  defimpl Enumerable do
    def reduce(
          %Exqlite.Stream{query: statement, conn: conn, params: params, options: opts},
          acc,
          fun
        )
        when is_binary(statement) do
      query = %Exqlite.Query{name: "", statement: statement}

      case DBConnection.prepare_execute(conn, query, params, opts) do
        {:ok, _, %{rows: _rows} = result} ->
          Enumerable.reduce([result], acc, fun)

        {:error, err} ->
          raise err
      end
    end

    def member?(_, _), do: {:error, __MODULE__}

    def count(_), do: {:error, __MODULE__}

    def slice(_), do: {:error, __MODULE__}
  end
end
