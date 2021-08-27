defmodule Ecto.Adapters.SQLite3.DataTypeTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQLite3.DataType

  setup do
    Application.put_env(:ecto_sqlite3, :binary_id_type, :string)
    Application.put_env(:ecto_sqlite3, :uuid_type, :string)

    on_exit(fn ->
      Application.put_env(:ecto_sqlite3, :binary_id_type, :string)
      Application.put_env(:ecto_sqlite3, :uuid_type, :string)
    end)
  end

  describe ".column_type/2" do
    test ":id is INTEGER" do
      assert DataType.column_type(:id, nil) == "INTEGER"
    end

    test ":serial is INTEGER" do
      assert DataType.column_type(:serial, nil) == "INTEGER"
    end

    test ":bigserial is INTEGER" do
      assert DataType.column_type(:bigserial, nil) == "INTEGER"
    end

    test ":binary_id is TEXT_UUID OR UUID" do
      assert DataType.column_type(:binary_id, nil) == "TEXT_UUID"

      Application.put_env(:ecto_sqlite3, :binary_id_type, :binary)

      assert DataType.column_type(:binary_id, nil) == "UUID"
    end

    test ":string is TEXT" do
      assert DataType.column_type(:string, nil) == "TEXT"
    end

    test ":uuid is TEXT_UUID or UUID" do
      assert DataType.column_type(:uuid, nil) == "TEXT_UUID"

      Application.put_env(:ecto_sqlite3, :uuid_type, :binary)

      assert DataType.column_type(:uuid, nil) == "UUID"
    end

    test ":map is JSON" do
      assert DataType.column_type(:map, nil) == "JSON"
    end

    test "{:map, _} is JSON" do
      assert DataType.column_type({:map, %{}}, nil) == "JSON"
    end

    test ":array is JSON" do
      assert DataType.column_type(:array, nil) == "JSON"
    end

    test "{:array, _} is JSON" do
      assert DataType.column_type({:array, []}, nil) == "JSON"
    end

    test ":float is NUMERIC" do
      assert DataType.column_type(:float, nil) == "NUMERIC"
    end

    test ":decimal with no options is DECIMAL" do
      assert DataType.column_type(:decimal, nil) == "DECIMAL"
    end

    test ":decimal with empty options is DECIMAL" do
      assert DataType.column_type(:decimal, []) == "DECIMAL"
    end

    test ":decimal with precision and scale is DECIMAL" do
      assert DataType.column_type(:decimal, precision: 5, scale: 2) == "DECIMAL(5,2)"
    end

    test ":binary is BLOB" do
      assert DataType.column_type(:binary, nil) == "BLOB"
    end

    test ":utc_datetime is DATETIME" do
      assert DataType.column_type(:utc_datetime, nil) == "TEXT_DATETIME"
    end

    test ":utc_datetime_usec is DATETIME" do
      assert DataType.column_type(:utc_datetime_usec, nil) == "TEXT_DATETIME"
    end

    test ":naive_datetime is DATETIME" do
      assert DataType.column_type(:naive_datetime, nil) == "TEXT_DATETIME"
    end

    test ":naive_datetime_usec is DATETIME" do
      assert DataType.column_type(:naive_datetime_usec, nil) == "TEXT_DATETIME"
    end
  end
end
