Logger.configure(level: :info)

Application.put_env(:ecto, :json_library, Jason)
Application.put_env(:ecto, :primary_key_type, :id)
Application.put_env(:ecto, :async_integration_tests, false)

ecto = Mix.Project.deps_paths()[:ecto]
Code.require_file("#{ecto}/integration_test/support/schemas.exs", __DIR__)

Application.put_env(:exqlite, Ecto.Integration.TestRepo,
  adapter: Ecto.Adapters.Exqlite,
  database: "/tmp/exqlite_sandbox_test.db",
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 1,
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

{:ok, _} = Ecto.Integration.TestRepo.start_link()

:ok =
  Ecto.Migrator.up(
    Ecto.Integration.TestRepo,
    0,
    Exqlite.Integration.Migration,
    log: false
  )

Process.flag(:trap_exit, true)

ExUnit.start()
