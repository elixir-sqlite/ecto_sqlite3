defmodule Ecto.Adapters.SQLite3.Codec do
  @moduledoc false

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
    Application.get_env(:ecto_sqlite3, :json_library, Jason).decode(x)
  end

  def json_decode(_), do: :error

  def float_decode(nil), do: {:ok, nil}
  def float_decode(%Decimal{} = decimal), do: {:ok, Decimal.to_float(decimal)}
  def float_decode(x) when is_integer(x), do: {:ok, x / 1}
  def float_decode(_), do: :error

  def decimal_decode(nil), do: {:ok, nil}

  def decimal_decode(x) when is_float(x) do
    {:ok, Decimal.from_float(x)}
  catch
    Decimal.Error -> :error
  end

  def decimal_decode(x) when is_binary(x) or is_integer(x) do
    {:ok, Decimal.new(x)}
  catch
    Decimal.Error -> :error
  end

  def decimal_decode(_), do: :error

  def utc_datetime_decode(nil), do: {:ok, nil}

  def utc_datetime_decode(val) do
    with {:ok, naive} <- NaiveDateTime.from_iso8601(val),
         {:ok, dt} <- DateTime.from_naive(naive, "Etc/UTC") do
      {:ok, dt}
    else
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

  def time_decode(nil), do: {:ok, nil}

  def time_decode(value) do
    case Time.from_iso8601(value) do
      {:ok, _time} = result -> result
      {:error, _} -> :error
    end
  end

  def json_encode(value) when is_bitstring(value), do: {:ok, value}

  def json_encode(value) do
    Application.get_env(:ecto_sqlite3, :json_library, Jason).encode(value)
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

  @text_datetime_format "%Y-%m-%d %H:%M:%S"

  def utc_datetime_encode(%{time_zone: "Etc/UTC"} = value, :iso8601) do
    {:ok, NaiveDateTime.to_iso8601(value)}
  end

  def utc_datetime_encode(%{time_zone: "Etc/UTC"} = value, :text_datetime) do
    {:ok, Calendar.strftime(value, @text_datetime_format)}
  end

  def utc_datetime_encode(%{time_zone: "Etc/UTC"}, type) do
    raise ArgumentError,
          "expected datetime type to be either `:iso8601` or `:text_datetime`, but received #{inspect(type)}"
  end

  def naive_datetime_encode(value, :iso8601) do
    {:ok, NaiveDateTime.to_iso8601(value)}
  end

  def naive_datetime_encode(value, :text_datetime) do
    {:ok, Calendar.strftime(value, @text_datetime_format)}
  end

  def naive_datetime_encode(_value, type) do
    raise ArgumentError,
          "expected datetime type to be either `:iso8601` or `:text_datetime`, but received `#{inspect(type)}`"
  end
end
