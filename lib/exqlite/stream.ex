defmodule Exqlite.Stream do
  @moduledoc false
  defstruct [:conn, :query, :params, :options]
  @type t :: %Exqlite.Stream{}

  defimpl Enumerable do
    def reduce(%Exqlite.Stream{query: %Exqlite.Query{} = query} = stream, acc, fun) do
      %Exqlite.Stream{conn: conn, params: params, options: opts} = stream

      stream = %DBConnection.Stream{
        conn: conn,
        query: query,
        params: params,
        opts: opts
      }

      DBConnection.reduce(stream, acc, fun)
    end

    def reduce(%Exqlite.Stream{query: statement} = stream, acc, fun) do
      %Exqlite.Stream{conn: conn, params: params, options: opts} = stream
      query = %Exqlite.Query{name: "", statement: statement}

      stream = %DBConnection.PrepareStream{
        conn: conn,
        query: query,
        params: params,
        opts: opts
      }

      DBConnection.reduce(stream, acc, fun)
    end

    def member?(_, _), do: {:error, __MODULE__}

    def count(_), do: {:error, __MODULE__}

    def slice(_), do: {:error, __MODULE__}
  end
end
