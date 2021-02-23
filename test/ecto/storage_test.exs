defmodule Exqlite.Test.Ecto.StorageTest do
  use ExUnit.Case
  alias Ecto.Adapters.Exqlite

  describe "storage_up" do
    test "create database" do
      opts = [database: Temp.path!()]
      assert Exqlite.storage_up(opts) == :ok
      assert File.exists?(opts[:database])
    end

    test "does not fail on second call" do
      opts = [database: Temp.path!()]
      assert Exqlite.storage_up(opts) == :ok
      assert File.exists?(opts[:database])
      assert Exqlite.storage_up(opts) == :ok
      File.rm(opts[:database])
    end

    test "fails with helpful error message if no database specified" do
      opts = []

      assert_raise KeyError, "key :database not found in: []", fn ->
        Exqlite.storage_up(opts)
      end
    end
  end

  test "storage down (twice)" do
    opts = [database: Temp.path!()]
    assert Exqlite.storage_up(opts) == :ok
    assert Exqlite.storage_down(opts) == :ok
    refute File.exists?(opts[:database])
    assert Exqlite.storage_down(opts) == {:error, :already_down}
  end
end
