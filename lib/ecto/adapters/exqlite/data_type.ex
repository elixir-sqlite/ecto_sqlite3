defmodule Ecto.Adapters.Exqlite.DataType do
  # Simple column types. Note that we ignore options like :size, :precision,
  # etc. because columns do not have types, and SQLite will not coerce any
  # stored value. Thus, "strings" are all text and "numerics" have arbitrary
  # precision regardless of the declared column type. Decimals are the
  # only exception.
  def column_type(:id, _query), do: "INTEGER"
  def column_type(:serial, _query), do: "INTEGER"
  def column_type(:bigserial, _query), do: "INTEGER"
  # TODO: We should make this configurable
  def column_type(:binary_id, _query), do: "TEXT"
  def column_type(:string, _query), do: "TEXT"
  def column_type(:float, _query), do: "NUMERIC"
  def column_type(:binary, _query), do: "BLOB"
  # TODO: We should make this configurable
  # SQLite3 does not support uuid
  def column_type(:uuid, _query), do: "TEXT"
  def column_type(:map, _query), do: "JSON"
  def column_type(:array, _query), do: "JSON"
  def column_type({:map, _}, _query), do: "JSON"
  def column_type({:array, _}, _query), do: "JSON"
  def column_type(:utc_datetime, _query), do: "DATETIME"
  def column_type(:utc_datetime_usec, _query), do: "DATETIME"
  def column_type(:naive_datetime, _query), do: "DATETIME"
  def column_type(:naive_datetime_usec, _query), do: "DATETIME"

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
