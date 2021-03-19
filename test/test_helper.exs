Logger.configure(level: :info)

Application.put_env(:ecto, :primary_key_type, :id)
Application.put_env(:ecto, :async_integration_tests, false)

ecto = Mix.Project.deps_paths()[:ecto]
Code.require_file("#{ecto}/integration_test/support/schemas.exs", __DIR__)

alias Ecto.Integration.TestRepo

Application.put_env(:ecto_sqlite3, TestRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "/tmp/exqlite_sandbox_test.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
)

defmodule Ecto.Integration.Case do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    #on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(TestRepo) end)
  end
end

{:ok, _} = Ecto.Adapters.SQLite3.ensure_all_started(TestRepo.config(), :temporary)

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.SQLite3.storage_down(TestRepo.config())
:ok = Ecto.Adapters.SQLite3.storage_up(TestRepo.config())

{:ok, _} = TestRepo.start_link()

:ok = Ecto.Migrator.up(TestRepo, 0, EctoSQLite3.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
Process.flag(:trap_exit, true)

ExUnit.start()
