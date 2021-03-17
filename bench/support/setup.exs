Code.require_file("repo.exs", __DIR__)
Code.require_file("migrations.exs", __DIR__)
Code.require_file("schemas.exs", __DIR__)

alias Ecto.Bench.{PgRepo, MyXQLRepo, ExqliteRepo, CreateUser}

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(PgRepo.config(), :temporary)
{:ok, _} = Ecto.Adapters.MyXQL.ensure_all_started(MyXQLRepo.config(), :temporary)
{:ok, _} = Ecto.Adapters.Exqlite.ensure_all_started(ExqliteRepo.config(), :temporary)

_ = Ecto.Adapters.Postgres.storage_down(PgRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(PgRepo.config())

_ = Ecto.Adapters.MyXQL.storage_down(MyXQLRepo.config())
:ok = Ecto.Adapters.MyXQL.storage_up(MyXQLRepo.config())

_ = Ecto.Adapters.Exqlite.storage_down(ExqliteRepo.config())
:ok = Ecto.Adapters.Exqlite.storage_up(ExqliteRepo.config())

{:ok, _pid} = PgRepo.start_link(log: false)
{:ok, _pid} = MyXQLRepo.start_link(log: false)
{:ok, _pid} = ExqliteRepo.start_link(log: false)

:ok = Ecto.Migrator.up(PgRepo, 0, CreateUser, log: false)
:ok = Ecto.Migrator.up(MyXQLRepo, 0, CreateUser, log: false)
:ok = Ecto.Migrator.up(ExqliteRepo, 0, CreateUser, log: false)
