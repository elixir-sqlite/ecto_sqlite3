# -----------------------------------Goal--------------------------------------
# Compare the performance of querying all objects of the different supported
# databases

# -------------------------------Description-----------------------------------
# This benchmark tracks performance of querying a set of objects registered in
# the database with Repo.all/2 function. The query pass through
# the steps of translating the SQL statements, sending them to the database and
# load the results into Ecto structures. Both, Ecto Adapters and Database itself
# play a role and can affect the results of this benchmark.

# ----------------------------Factors(don't change)---------------------------
# Different adapters supported by Ecto with the proper database up and running

# ----------------------------Parameters(change)-------------------------------
# There is only a unique parameter in this benchmark, the User objects to be
# fetched.

Code.require_file("../../support/setup.exs", __DIR__)

alias Ecto.Bench.User

limit = 1_000

users =
  1..limit
  |> Enum.map(fn _ -> User.sample_data() end)

# We need to insert data to fetch
Ecto.Bench.SQLite3Repo.insert_all(User, users)
Ecto.Bench.PgRepo.insert_all(User, users)
Ecto.Bench.MyXQLRepo.insert_all(User, users)

jobs = %{
  "SQLite3 Repo.all/2" => fn -> Ecto.Bench.SQLite3Repo.all(User, limit: limit) end,
  "Pg Repo.all/2" => fn -> Ecto.Bench.PgRepo.all(User, limit: limit) end,
  "MyXQL Repo.all/2" => fn -> Ecto.Bench.MyXQLRepo.all(User, limit: limit) end
}

path = System.get_env("BENCHMARKS_OUTPUT_PATH") || "bench/results"

Benchee.run(
  jobs,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.Markdown,
      file: Path.join(path, "all.md")}
  ],
  time: 10,
  after_each: fn results ->
    ^limit = length(results)
  end
)

# Clean inserted data
Ecto.Bench.SQLite3Repo.delete_all(User)
Ecto.Bench.PgRepo.delete_all(User)
Ecto.Bench.MyXQLRepo.delete_all(User)
