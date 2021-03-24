# -----------------------------------Goal--------------------------------------
# Compare the performance of inserting changesets and structs in the different
# supported databases

# -------------------------------Description-----------------------------------
# This benchmark tracks performance of inserting changesets and structs in the
# database with Repo.insert!/1 function. The query pass through
# the steps of translating the SQL statements, sending them to the database and
# returning the result of the transaction. Both, Ecto Adapters and Database itself
# play a role and can affect the results of this benchmark.

# ----------------------------Factors(don't change)---------------------------
# Different adapters supported by Ecto with the proper database up and running

# ----------------------------Parameters(change)-------------------------------
# Different inputs to be inserted, aka Changesets and Structs

Code.require_file("../../support/setup.exs", __DIR__)

alias Ecto.Bench.User

inputs = %{
  "Struct" => struct(User, User.sample_data()),
  "Changeset" => User.changeset(User.sample_data())
}

jobs = %{
  "SQLite3 Insert" => fn entry -> Ecto.Bench.SQLite3Repo.insert!(entry) end,
  "Pg Insert" => fn entry -> Ecto.Bench.PgRepo.insert!(entry) end,
  "MyXQL Insert" => fn entry -> Ecto.Bench.MyXQLRepo.insert!(entry) end
}

path = System.get_env("BENCHMARKS_OUTPUT_PATH") || "bench/results"

Benchee.run(
  jobs,
  inputs: inputs,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.Markdown, file: Path.join(path, "insert.md")}
  ]
)

# Clean inserted data
Ecto.Bench.SQLite3Repo.delete_all(User)
Ecto.Bench.PgRepo.delete_all(User)
Ecto.Bench.MyXQLRepo.delete_all(User)
