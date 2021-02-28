defmodule Ecto.Adapters.ExqliteTest do
  use ExUnit.Case

  alias Ecto.Adapters.Exqlite

  describe ".storage_up/1" do
    test "create database" do
      opts = [database: Temp.path!()]

      assert Exqlite.storage_up(opts) == :ok
      assert File.exists?(opts[:database])

      File.rm(opts[:database])
    end

    test "does not fail on second call" do
      opts = [database: Temp.path!()]

      assert Exqlite.storage_up(opts) == :ok
      assert File.exists?(opts[:database])
      assert Exqlite.storage_up(opts) == {:error, :already_up}

      File.rm(opts[:database])
    end

    test "fails with helpful error message if no database specified" do
      assert_raise(
        ArgumentError,
        """
        No SQLite database path specified. Please check the configuration for your Repo.
        Your config/*.exs file should have something like this in it:

          config :my_app, MyApp.Repo,
            adapter: Ecto.Adapters.Exqlite,
            database: "/path/to/sqlite/database"
        """,
        fn -> Exqlite.storage_up(mumble: "no database here") == :ok end
      )
    end
  end

  describe ".storage_down/2" do
    test "storage down (twice)" do
      opts = [database: Temp.path!()]

      assert Exqlite.storage_up(opts) == :ok
      assert Exqlite.storage_down(opts) == :ok
      refute File.exists?(opts[:database])
      assert Exqlite.storage_down(opts) == {:error, :already_down}

      File.rm(opts[:database])
    end
  end
end
