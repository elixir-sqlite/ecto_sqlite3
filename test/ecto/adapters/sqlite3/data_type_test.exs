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

    test ":binary_id is TEXT OR UUID" do
      assert DataType.column_type(:binary_id, nil) == "TEXT"

      Application.put_env(:ecto_sqlite3, :binary_id_type, :binary)

      assert DataType.column_type(:binary_id, nil) == "BLOB"
    end

    test ":string is TEXT" do
      assert DataType.column_type(:string, nil) == "TEXT"
    end

    test ":uuid is TEXT or UUID" do
      assert DataType.column_type(:uuid, nil) == "TEXT"

      Application.put_env(:ecto_sqlite3, :uuid_type, :binary)

      assert DataType.column_type(:uuid, nil) == "BLOB"
    end

    test ":map is TEXT" do
      assert DataType.column_type(:map, nil) == "TEXT"
    end

    test "{:map, _} is TEXT" do
      assert DataType.column_type({:map, %{}}, nil) == "TEXT"
    end

    test ":array is TEXT" do
      assert DataType.column_type(:array, nil) == "TEXT"
    end

    test "{:array, _} is TEXT" do
      assert DataType.column_type({:array, []}, nil) == "TEXT"
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

    test ":utc_datetime is TEXT" do
      assert DataType.column_type(:utc_datetime, nil) == "TEXT"
    end

    test ":utc_datetime_usec is TEXT" do
      assert DataType.column_type(:utc_datetime_usec, nil) == "TEXT"
    end

    test ":naive_datetime is TEXT" do
      assert DataType.column_type(:naive_datetime, nil) == "TEXT"
    end

    test ":naive_datetime_usec is TEXT" do
      assert DataType.column_type(:naive_datetime_usec, nil) == "TEXT"
    end
  end
end
