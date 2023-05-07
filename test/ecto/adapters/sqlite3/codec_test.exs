defmodule Ecto.Adapters.SQLite3.CodecTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQLite3.Codec

  describe ".bool_decode/1" do
    test "0" do
      {:ok, false} = Codec.bool_decode(0)
      {:ok, false} = Codec.bool_decode("0")
    end

    test "FALSE" do
      {:ok, false} = Codec.bool_decode("FALSE")
    end

    test "1" do
      {:ok, true} = Codec.bool_decode(1)
      {:ok, true} = Codec.bool_decode("1")
    end

    test "TRUE" do
      {:ok, true} = Codec.bool_decode("TRUE")
    end
  end

  describe ".json_decode/1" do
    test "nil" do
      {:ok, nil} = Codec.json_decode(nil)
    end

    test "valid json" do
      {:ok, %{}} = Codec.json_decode("{}")
      {:ok, []} = Codec.json_decode("[]")
      {:ok, %{"foo" => 1}} = Codec.json_decode(~s|{"foo":1}|)
    end

    test "handles malformed json" do
      {:error, _} = Codec.json_decode("")
      {:error, _} = Codec.json_decode(" ")
      {:error, _} = Codec.json_decode("{")
      {:error, _} = Codec.json_decode("[")
    end
  end

  describe ".float_decode/1" do
    test "nil" do
      {:ok, nil} = Codec.float_decode(nil)
    end

    test "integer" do
      {:ok, 1.0} = Codec.float_decode(1)
      {:ok, 2.0} = Codec.float_decode(2)
    end

    test "Decimal" do
      {:ok, 1.0} = Codec.float_decode(Decimal.new("1.0"))
    end
  end

  describe ".decimal_decode/1" do
    test "nil" do
      {:ok, nil} = Codec.decimal_decode(nil)
    end

    test "string" do
      decimal = Decimal.new("1")
      {:ok, ^decimal} = Codec.decimal_decode("1")

      decimal = Decimal.new("1.0")
      {:ok, ^decimal} = Codec.decimal_decode("1.0")
    end

    test "integer" do
      decimal = Decimal.new("2")
      {:ok, ^decimal} = Codec.decimal_decode(2)
    end

    test "float" do
      decimal = Decimal.from_float(1.2)
      {:ok, ^decimal} = Codec.decimal_decode(1.2)
    end
  end

  describe ".time_decode/1" do
    test "nil" do
      {:ok, nil} = Codec.time_decode(nil)
    end

    test "string" do
      {:ok, time} = Time.from_iso8601("23:50:07")
      assert {:ok, ^time} = Codec.time_decode("23:50:07")

      {:ok, time} = Time.from_iso8601("23:50:07Z")
      assert {:ok, ^time} = Codec.time_decode("23:50:07Z")

      {:ok, time} = Time.from_iso8601("T23:50:07Z")
      assert {:ok, ^time} = Codec.time_decode("T23:50:07Z")

      {:ok, time} = Time.from_iso8601("23:50:07,0123456")
      assert {:ok, ^time} = Codec.time_decode("23:50:07,0123456")

      {:ok, time} = Time.from_iso8601("23:50:07.0123456")
      assert {:ok, ^time} = Codec.time_decode("23:50:07.0123456")

      {:ok, time} = Time.from_iso8601("23:50:07.123Z")
      assert {:ok, ^time} = Codec.time_decode("23:50:07.123Z")
    end
  end

  describe ".utc_datetime_decode/1" do
    test "nil" do
      assert {:ok, nil} = Codec.utc_datetime_decode(nil)
    end

    test "string" do
      {:ok, dt} = DateTime.from_naive(~N[2021-08-25 10:58:59Z], "Etc/UTC")
      assert {:ok, ^dt} = Codec.utc_datetime_decode("2021-08-25 10:58:59")

      {:ok, dt} = DateTime.from_naive(~N[2021-08-25 10:58:59.111111], "Etc/UTC")
      assert {:ok, ^dt} = Codec.utc_datetime_decode("2021-08-25 10:58:59.111111")
    end

    test "ignores timezone offset if present" do
      {:ok, dt} = DateTime.from_naive(~N[2021-08-25 10:58:59.111111], "Etc/UTC")
      assert {:ok, ^dt} = Codec.utc_datetime_decode("2021-08-25 10:58:59.111111Z")
      assert {:ok, ^dt} = Codec.utc_datetime_decode("2021-08-25 10:58:59.111111+02:30")
    end
  end

  describe ".utc_datetime_encode/2" do
    setup do
      [dt: ~U[2021-08-25 10:58:59Z]]
    end

    test "iso8601", %{dt: dt} do
      dt_str = "2021-08-25T10:58:59"
      assert {:ok, ^dt_str} = Codec.utc_datetime_encode(dt, :iso8601)
    end

    test ":text_datetime", %{dt: dt} do
      dt_str = "2021-08-25 10:58:59"
      assert {:ok, ^dt_str} = Codec.utc_datetime_encode(dt, :text_datetime)
    end

    test "unknown datetime type", %{dt: dt} do
      msg =
        "expected datetime type to be either `:iso8601` or `:text_datetime`, but received `:whatsthis`"

      assert_raise ArgumentError, msg, fn ->
        Codec.naive_datetime_encode(dt, :whatsthis)
      end
    end
  end

  describe ".naive_datetime_encode/2" do
    setup do
      [dt: ~U[2021-08-25 10:58:59Z], dt_str: "2021-08-25T10:58:59"]
    end

    test "iso8601", %{dt: dt} do
      dt_str = "2021-08-25T10:58:59"
      assert {:ok, ^dt_str} = Codec.naive_datetime_encode(dt, :iso8601)
    end

    test ":text_datetime", %{dt: dt} do
      dt_str = "2021-08-25 10:58:59"
      assert {:ok, ^dt_str} = Codec.naive_datetime_encode(dt, :text_datetime)
    end

    test "unknown datetime type", %{dt: dt} do
      msg =
        "expected datetime type to be either `:iso8601` or `:text_datetime`, but received `:whatsthis`"

      assert_raise ArgumentError, msg, fn ->
        Codec.naive_datetime_encode(dt, :whatsthis)
      end
    end
  end

  describe ".date_encode/2" do
    setup do
      [
        date: ~D[2011-01-09],
        datetime: ~U[2011-01-09 08:46:08.00Z]
      ]
    end

    test "on %Date{} structs", %{date: date} do
      {:ok, "2011-01-09"} = Codec.date_encode(date, :iso8601)
    end
  end
end
