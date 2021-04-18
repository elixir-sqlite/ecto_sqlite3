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
  def column_type(:bigint, _opts), do: "INTEGER"
  # TODO: We should make this configurable
  def column_type(:binary_id, _opts), do: "TEXT"
  def column_type(:string, _opts), do: "TEXT"
  def column_type(:float, _opts), do: "NUMERIC"
  def column_type(:binary, _opts), do: "BLOB"
  # TODO: We should make this configurable
  # SQLite3 does not support uuid
  def column_type(:uuid, _opts), do: "TEXT"
  def column_type(:map, _opts), do: "JSON"
  def column_type(:array, _opts), do: "JSON"
  def column_type({:map, _}, _opts), do: "JSON"
  def column_type({:array, _}, _opts), do: "JSON"
  def column_type(:utc_datetime, _opts), do: "TEXT_DATETIME"
  def column_type(:utc_datetime_usec, _opts), do: "TEXT_DATETIME"
  def column_type(:naive_datetime, _opts), do: "TEXT_DATETIME"
  def column_type(:naive_datetime_usec, _opts), do: "TEXT_DATETIME"
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

  def column_type(type, _) do
    type
    |> Atom.to_string()
    |> String.upcase()
  end
end
