defmodule Ecto.Adapters.SQLite3.DataType do
  @moduledoc false

  # Simple column types. Note that we ignore options like :size, :precision,
  # etc. because columns do not have types, and SQLite will not coerce any
  # stored value. Thus, "strings" are all text and "numerics" have arbitrary
  # precision regardless of the declared column type. Decimals are the
  # only exception.

  @spec column_type(atom(), Keyword.t()) :: String.t()
  def column_type(:id, _opts), do: "INTEGER"
  def column_type(:serial, _opts), do: "INTEGER"
  def column_type(:bigserial, _opts), do: "INTEGER"
  def column_type(:boolean, _opts), do: "INTEGER"
  def column_type(:integer, _opts), do: "INTEGER"
  def column_type(:bigint, _opts), do: "INTEGER"
  def column_type(:string, _opts), do: "TEXT"
  def column_type(:float, _opts), do: "NUMERIC"
  def column_type(:binary, _opts), do: "BLOB"
  def column_type(:date, _opts), do: "TEXT"
  def column_type(:utc_datetime, _opts), do: "TEXT"
  def column_type(:utc_datetime_usec, _opts), do: "TEXT"
  def column_type(:naive_datetime, _opts), do: "TEXT"
  def column_type(:naive_datetime_usec, _opts), do: "TEXT"
  def column_type(:time, _opts), do: "TEXT"
  def column_type(:time_usec, _opts), do: "TEXT"
  def column_type(:timestamp, _opts), do: "TEXT"
  def column_type(:decimal, nil), do: "DECIMAL"

  def column_type(:decimal, opts) do
    # We only store precision and scale for DECIMAL.
    precision = Keyword.get(opts, :precision)
    scale = Keyword.get(opts, :scale, 0)

    if precision do
      "DECIMAL(#{precision},#{scale})"
    else
      "DECIMAL"
    end
  end

  def column_type(:array, _opts) do
    case Application.get_env(:ecto_sqlite3, :array_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type({:array, _}, _opts) do
    case Application.get_env(:ecto_sqlite3, :array_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type(:binary_id, _opts) do
    case Application.get_env(:ecto_sqlite3, :binary_id_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type(:map, _opts) do
    case Application.get_env(:ecto_sqlite3, :map_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type({:map, _}, _opts) do
    case Application.get_env(:ecto_sqlite3, :map_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type(:uuid, _opts) do
    case Application.get_env(:ecto_sqlite3, :uuid_type, :string) do
      :string -> "TEXT"
      :binary -> "BLOB"
    end
  end

  def column_type(type, _) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.upcase()
  end

  def column_type(type, _) do
    raise ArgumentError,
          "unsupported type `#{inspect(type)}`. The type can either be an atom, a string " <>
            "or a tuple of the form `{:map, t}` or `{:array, t}` where `t` itself follows the same conditions."
  end
end
