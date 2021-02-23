defmodule Ecto.Adapters.ExqliteTest do
  use ExUnit.Case

  alias Ecto.Adapters.Exqlite

  describe ".storage_up/1" do
    test "fails with :already_up on second call" do
      tmp = [database: Temp.path!()]
      assert Exqlite.storage_up(tmp) == :ok
      assert File.exists?(tmp[:database])
      assert Exqlite.storage_up(tmp) == {:error, :already_up}
    end

    test "fails with helpful error message if no database specified" do
      assert_raise ArgumentError,
                   """
                   No SQLite database path specified. Please check the configuration for your Repo.
                   Your config/*.exs file should have something like this in it:

                     config :my_app, MyApp.Repo,
                       adapter: Ecto.Adapters.Exqlite,
                       database: "/path/to/sqlite/database"
                   """,
                   fn -> Exqlite.storage_up(mumble: "no database here") == :ok end
    end
  end

  describe ".storage_down/2" do
    test "storage down (twice)" do
      tmp = [database: Temp.path!()]
      assert Exqlite.storage_up(tmp) == :ok
      assert Exqlite.storage_down(tmp) == :ok
      refute File.exists?(tmp[:database])
      assert Exqlite.storage_down(tmp) == {:error, :already_down}
    end
  end
end
