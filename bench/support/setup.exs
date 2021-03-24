Code.require_file("repo.exs", __DIR__)
Code.require_file("migrations.exs", __DIR__)
Code.require_file("schemas.exs", __DIR__)

alias Ecto.Bench.{PgRepo, MyXQLRepo, SQLite3Repo, CreateUser}

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(PgRepo.config(), :temporary)
{:ok, _} = Ecto.Adapters.MyXQL.ensure_all_started(MyXQLRepo.config(), :temporary)
{:ok, _} = Ecto.Adapters.SQLite3.ensure_all_started(SQLite3Repo.config(), :temporary)

_ = Ecto.Adapters.Postgres.storage_down(PgRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(PgRepo.config())

_ = Ecto.Adapters.MyXQL.storage_down(MyXQLRepo.config())
:ok = Ecto.Adapters.MyXQL.storage_up(MyXQLRepo.config())

_ = Ecto.Adapters.SQLite3.storage_down(SQLite3Repo.config())
:ok = Ecto.Adapters.SQLite3.storage_up(SQLite3Repo.config())

{:ok, _pid} = PgRepo.start_link(log: false)
{:ok, _pid} = MyXQLRepo.start_link(log: false)
{:ok, _pid} = SQLite3Repo.start_link(log: false)

:ok = Ecto.Migrator.up(PgRepo, 0, CreateUser, log: false)
:ok = Ecto.Migrator.up(MyXQLRepo, 0, CreateUser, log: false)
:ok = Ecto.Migrator.up(SQLite3Repo, 0, CreateUser, log: false)
