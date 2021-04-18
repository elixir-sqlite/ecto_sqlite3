ecto = Mix.Project.deps_paths()[:ecto]

Code.require_file "#{ecto}/integration_test/cases/assoc.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/joins.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/preload.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/repo.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/windows.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/interval.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/type.exs", __DIR__
Code.require_file "#{ecto}/integration_test/cases/repo.exs", __DIR__

ecto_sql = Mix.Project.deps_paths()[:ecto_sql]
# Code.require_file "#{ecto_sql}/integration_test/sql/lock.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/logging.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/sandbox.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/sql.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/stream.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/subquery.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/transaction.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/migration.exs", __DIR__
Code.require_file "#{ecto_sql}/integration_test/sql/migrator.exs", __DIR__
