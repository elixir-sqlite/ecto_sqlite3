defmodule Ecto.Adapters.Exqlite.Codec do
  def bool_decode(nil), do: {:ok, nil}
  def bool_decode(0), do: {:ok, false}
  def bool_decode("0"), do: {:ok, false}
  def bool_decode("FALSE"), do: {:ok, false}
  def bool_decode(1), do: {:ok, true}
  def bool_decode("1"), do: {:ok, true}
  def bool_decode("TRUE"), do: {:ok, true}
  def bool_decode(_), do: :error

  def json_decode(nil), do: {:ok, nil}

  def json_decode(x) when is_binary(x) do
    Application.get_env(:exqlite, :json_library, Jason).decode(x)
  end

  def json_decode(_), do: :error

  def float_decode(nil), do: {:ok, nil}
  def float_decode(%Decimal{} = decimal), do: {:ok, Decimal.to_float(decimal)}
  def float_decode(x) when is_integer(x), do: {:ok, x / 1}
  def float_decode(_), do: :error

  def decimal_decode(nil), do: {:ok, nil}

  def decimal_decode(x) when is_float(x) do
    try do
      {:ok, Decimal.from_float(x)}
    catch
      Decimal.Error -> :error
    end
  end

  def decimal_decode(x) when is_binary(x) or is_integer(x) do
    try do
      {:ok, Decimal.new(x)}
    catch
      Decimal.Error -> :error
    end
  end

  def decimal_decode(_), do: :error

  def datetime_decode(nil), do: {:ok, nil}

  def datetime_decode(val) do
    # TODO: Should we be preserving the timezone? SQLite3 stores everything
    #       shifted to UTC. sqlite_ecto2 used a custom field type "TEXT_DATETIME"
    #       to preserve the original string inserted. But I don't know if that
    #       is desirable or not.
    #
    #       @warmwaffles 2021-02-28
    case DateTime.from_iso8601(val) do
      {:ok, dt, _offset} -> {:ok, dt}
      _ -> :error
    end
  end

  def naive_datetime_decode(nil), do: {:ok, nil}

  def naive_datetime_decode(val) do
    case NaiveDateTime.from_iso8601(val) do
      {:ok, dt} -> {:ok, dt}
      _ -> :error
    end
  end

  def date_decode(nil), do: {:ok, nil}

  def date_decode(val) do
    case Date.from_iso8601(val) do
      {:ok, d} -> {:ok, d}
      _ -> :error
    end
  end

  def json_encode(value) do
    Application.get_env(:exqlite, :json_library, Jason).encode(value)
  end

  def blob_encode(value), do: {:ok, {:blob, value}}

  def bool_encode(false), do: {:ok, 0}
  def bool_encode(true), do: {:ok, 1}

  def decimal_encode(%Decimal{} = x) do
    {:ok, Decimal.to_string(x, :normal)}
  end
  # def decimal_encode(x), do: {:ok, x}

  def time_encode(value) do
    {:ok, value}
  end

  def naive_datetime_encode(value) do
    {:ok, NaiveDateTime.to_iso8601(value)}
  end
end
