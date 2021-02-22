Logger.configure(level: :info)

Application.put_env(:ecto, :primary_key_type, :id)
Application.put_env(:ecto, :async_integration_tests, false)

ecto = Mix.Project.deps_paths()[:ecto]
Code.require_file("#{ecto}/integration_test/support/schemas.exs", __DIR__)

Application.put_env(:ecto_sql, Ecto.Integration.TestRepo,
  database: "/tmp/exqlite_sandbox_test.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
)

Application.put_env(:ecto_sql, Ecto.Integration.PoolRepo,
  adapter: Ecto.Adapters.Exqlite,
  database: "/tmp/exqlite_pool_test.db",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
)

{:ok, _} =
  Ecto.Adapters.Exqlite.ensure_all_started(
    Ecto.Integration.TestRepo.config(),
    :temporary
  )

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Exqlite.storage_down(Ecto.Integration.TestRepo.config())
:ok = Ecto.Adapters.Exqlite.storage_up(Ecto.Integration.TestRepo.config())

{:ok, _pid} = Ecto.Integration.TestRepo.start_link()
{:ok, _pid} = Ecto.Integration.PoolRepo.start_link()

# :ok = Ecto.Migrator.up(Ecto.Integration.TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(Ecto.Integration.TestRepo, :manual)
Process.flag(:trap_exit, true)

ExUnit.start()
