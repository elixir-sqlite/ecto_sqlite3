Logger.configure(level: :info)

Application.put_env(:ecto, :primary_key_type, :id)
Application.put_env(:ecto, :async_integration_tests, false)

ecto = Mix.Project.deps_paths()[:ecto]
ecto_sql = Mix.Project.deps_paths()[:ecto_sql]

Code.require_file("#{ecto_sql}/integration_test/support/repo.exs", __DIR__)

alias Ecto.Integration.TestRepo

Application.put_env(:exqlite, TestRepo,
  adapter: Ecto.Adapters.Exqlite,
  database: "/tmp/exqlite_integration_test.db",
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5,
  show_sensitive_data_on_connection_error: true
)

# Pool repo for non-async tests
alias Ecto.Integration.PoolRepo

Application.put_env(:exqlite, PoolRepo,
  adapter: Ecto.Adapters.Exqlite,
  database: "/tmp/exqlite_integration_pool_test.db",
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 5,
  show_sensitive_data_on_connection_error: true
)

defmodule Ecto.Integration.PoolRepo do
  use Ecto.Integration.Repo, otp_app: :exqlite, adapter: Ecto.Adapters.Exqlite
end

Code.require_file "#{ecto}/integration_test/support/schemas.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/support/migration.exs", __DIR__

defmodule Ecto.Integration.Case do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
  end
end

{:ok, _} = Ecto.Adapters.Exqlite.ensure_all_started(TestRepo.config(), :temporary)

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Exqlite.storage_down(TestRepo.config())
:ok = Ecto.Adapters.Exqlite.storage_up(TestRepo.config())

{:ok, _} = TestRepo.start_link()
{:ok, _pid} = PoolRepo.start_link()

# migrate the pool repo
case Ecto.Migrator.migrated_versions(PoolRepo) do
  [] ->
    :ok = Ecto.Migrator.up(PoolRepo, 0, Ecto.Integration.Migration, log: false)

  _ ->
    :ok = Ecto.Migrator.down(PoolRepo, 0, Ecto.Integration.Migration, log: false)
    :ok = Ecto.Migrator.up(PoolRepo, 0, Ecto.Integration.Migration, log: false)
end

:ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
Process.flag(:trap_exit, true)

ExUnit.start(
  exclude: [
    # SQLite does not have an array type
    :array_type,
    :transaction_isolation,
    :insert_cell_wise_defaults,
    :returning,
    :read_after_writes,
    # sqlite supports FKs, but does not return sufficient data
    # for ecto to support matching on a given constraint violation name
    # which is what most of the tests validate
    :foreign_key_constraint,

    # we should be able to fully/correctly support these, but don't currently
    :with_conflict_target,
    :without_conflict_target,
    :insert_select
  ]
)
