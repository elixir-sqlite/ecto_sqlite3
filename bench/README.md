# Ecto Benchmarks

## Results

| Benchmark | Description |
| --------- | ------------ |
| [load](results/load.md) | tracks performance of loading "raw" data into ecto structures |
| [to_sql](results/to_sql.md) | tracks performance of parsing `Ecto.Query` structures into "raw" SQL query strings |
| [insert](results/insert.md) |  tracks performance of inserting changesets and structs in the database with `Repo.insert!/1` function |

For reference, these results were run with a Sabrent Rocket Q 1TB NVMe SSD.

## Running the benchmarks

Ecto has a benchmark suite to track performance of sensitive operations. Benchmarks
are run using the [Benchee](https://github.com/PragTob/benchee) library and
need PostgreSQL and MySQL up and running.

To run the benchmarks tests just type in the console:

```sh
mix run bench/bench_helper.exs
```

Benchmarks are inside the `scripts/` directory and are divided into two
categories:

* `micro benchmarks`: Operations that don't actually interface with the database,
but might need it up and running to start the Ecto agents and processes.

* `macro benchmarks`: Operations that are actually run in the database. This are
more likely to integration tests.

You can also run a benchmark individually by giving the path to the benchmark
script instead of `bench/bench_helper.exs`.

### Docker
The easiest way to setup mysql and postgresql for the benchmarks is via Docker. Run the following commands to get an instance of each running.

```
docker run -p 3306:3306 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:8
docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:13.2
```
