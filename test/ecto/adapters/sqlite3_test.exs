defmodule Ecto.Adapters.SQLite3Test do
  use ExUnit.Case

  alias Ecto.Adapters.SQLite3

  describe ".storage_up/1" do
    test "create database" do
      opts = [database: Temp.path!()]

      assert SQLite3.storage_up(opts) == :ok
      assert File.exists?(opts[:database])

      File.rm(opts[:database])
    end

    test "does not fail on second call" do
      opts = [database: Temp.path!()]

      assert SQLite3.storage_up(opts) == :ok
      assert File.exists?(opts[:database])
      assert SQLite3.storage_up(opts) == {:error, :already_up}

      File.rm(opts[:database])
    end

    test "fails with helpful error message if no database specified" do
      assert_raise(
        ArgumentError,
        """
        No SQLite database path specified. Please check the configuration for your Repo.
        Your config/*.exs file should have something like this in it:

          config :my_app, MyApp.Repo,
            adapter: Ecto.Adapters.SQLite3,
            database: "/path/to/sqlite/database"
        """,
        fn -> SQLite3.storage_up(mumble: "no database here") == :ok end
      )
    end
  end

  describe ".storage_down/2" do
    test "storage down (twice)" do
      opts = [database: Temp.path!()]

      assert SQLite3.storage_up(opts) == :ok
      assert SQLite3.storage_down(opts) == :ok
      refute File.exists?(opts[:database])
      assert SQLite3.storage_down(opts) == {:error, :already_down}

      File.rm(opts[:database])
    end
  end
end
