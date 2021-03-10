defmodule Ecto.Adapters.Exqlite.CodecTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.Exqlite.Codec

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
end
