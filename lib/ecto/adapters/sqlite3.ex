defmodule Ecto.Adapters.SQLite3 do
  @moduledoc """
  Adapter module for SQLite3.

  It uses `Exqlite` for communicating to the database.

  ## Options

  The adapter supports a superset of the options provided by the
  underlying `Exqlite` driver.

  ### Provided options

    * `:database` - The path to the database. In memory is allowed. You can use
      `:memory` or `":memory:"` to designate that.
    * `:journal_mode` - Sets the journal mode for the sqlite connection. Can be
      one of the following `:delete`, `:truncate`, `:persist`, `:memory`,
      `:wal`, or `:off`. Defaults to `:wal`.
    * `:temp_store` - Sets the storage used for temporary tables. Default is
      `:default`. Allowed values are `:default`, `:file`, `:memory`.
    * `:synchronous` - Can be `:extra`, `:full`, `:normal`, or `:off`. Defaults
      to `:normal`.
    * `:foreign_keys` - Sets if foreign key checks should be enforced or not.
      Can be `:on` or `:off`. Default is `:on`.
    * `:cache_size` - Sets the cache size to be used for the connection. This is
      an odd setting as a positive value is the number of pages in memory to use
      and a negative value is the size in kilobytes to use. Default is `-64000`.
    * `:cache_spill` - The cache_spill pragma enables or disables the ability of
      the pager to spill dirty cache pages to the database file in the middle of
      a transaction. By default it is `:on`, and for most applications, it
      should remain so.
    * `:case_sensitive_like` - whether LIKE is case-sensitive or not. Can be
      `:off` or `:on`. Defaults to `:off`.
    * `:auto_vacuum` - Defaults to `:none`. Can be `:none`, `:full` or
      `:incremental`. Depending on the database size, `:incremental` may be
      beneficial.
    * `:locking_mode` - Defaults to `:normal`. Allowed values are `:normal` or
      `:exclusive`. See [sqlite documenation][1] for more information.
    * `:secure_delete` - Defaults to `:off`. Can be `:off` or `:on`. If `:on`, it will cause SQLite3
      to overwrite records that were deleted with zeros.
    * `:wal_auto_check_point` - Sets the write-ahead log auto-checkpoint
      interval. Default is `1000`. Setting the auto-checkpoint size to zero or a
      negative value turns auto-checkpointing off.
    * `:busy_timeout` - Sets the busy timeout in milliseconds for a connection.
      Default is `2000`.
    * `:pool_size` - the size of the connection pool. Defaults to `5`.

  For more information about the options above, see [sqlite documenation][1]

  ### Differences between SQLite and Ecto SQLite defaults

  For the most part, the defaults we provide above match the defaults that SQLite usually
  ships with. However, SQLite has conservative defaults due to its need to be strictly backwards
  compatible, so some of them do not necessarily match "best practices". Below are the defaults
  we provide above that differ from the normal SQLite defaults, along with rationale.

    * `:journal_mode` - we use `:wal`, as it is vastly superior
      for concurrent access. SQLite usually defaults to `:delete`.
      See [SQLite documentation][2] for more info.
    * `:temp_store` - we use `:memory`, which increases performance a bit.
      SQLite usually defaults to `:file`.
    * `:foreign_keys` - we set it to `:on`, for better relational guarantees.
      This is also the default of the underlying `Exqlite` driver.
      SQLite usually defaults to `:off` for backwards compat.
    * `:busy_timeout` - we set it to `2000`, to better enable concurrent access.
      This is also the default of `Exqlite`. SQLite usually defaults to `0`.
    * `:cache_size` - we set it to `-64000`, to speed up access of data.
      SQLite usually defaults to `-2000`.

  These defaults can of course be overridden, as noted above, to suit other needs.

  [1]: https://www.sqlite.org/pragma.html
  [2]: https://sqlite.org/wal.html

  ## Limitations

  There are some limitations when using Ecto with SQLite that one needs
  to be aware of. The ones listed below are specific to Ecto usage, but it
  is encouraged to also view the guidance on [when to use SQLite][4] provided
  by the SQLite documentation, as well.

  ### Async Sandbox testing

  The Ecto SQLite3 adapter does not support async tests when used with
  `Ecto.Adapters.SQL.Sandbox`. This is due to SQLite only allowing up one
  write transaction at a time, which often does not work with the Sandbox approach of
  wrapping each test in a transaction.

  ### LIKE match on BLOB columns

  We have the DSQLITE_LIKE_DOESNT_MATCH_BLOBS compile-time option set to true,
  as [recommended][3] by SQLite. This means you cannot do LIKE queries on BLOB columns.

  ### Case sensitivity

  Case sensitivty for `LIKE` is off by default, and controlled by the `:case_sensitive_like`
  option outlined above.

  However, for equality comparison, case sensitivity is always _on_.
  If you want to make a column not be case sensitive, for email storage for example, you can
  make it case insensitive by using the [`COLLATE NOCASE`][6] option in SQLite. This is configured
  via the `:collate` option.

  So instead of:

      add :email, :string

  You would do:

      add :email, :string, collate: :nocase

  ### Schemaless queries

  Using [schemaless Ecto queries][7] will not work well with SQLite. This is because
  the Ecto SQLite adapter relies heavily on the schema to support a rich array of Elixir
  types, despite the fact SQLite only has [five storage classes][5]. The query will still
  work and return data, but you will need to do this mapping on your own.

  [3]: https://www.sqlite.org/compile.html
  [4]: https://www.sqlite.org/whentouse.html
  [5]: https://www.sqlite.org/datatype3.html
  [6]: https://www.sqlite.org/datatype3.html#collating_sequences
  [7]: https://hexdocs.pm/ecto/schemaless-queries.html
  """

  use Ecto.Adapters.SQL,
    driver: :exqlite

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

  alias Ecto.Adapters.SQLite3.Codec

  @impl Ecto.Adapter.Storage
  def storage_down(options) do
    db_path = Keyword.fetch!(options, :database)

    with :ok <- File.rm(db_path) do
      File.rm(db_path <> "-shm")
      File.rm(db_path <> "-wal")
      :ok
    else
      _ -> {:error, :already_down}
    end
  end

  @impl Ecto.Adapter.Storage
  def storage_status(options) do
    db_path = Keyword.fetch!(options, :database)

    if File.exists?(db_path) do
      :up
    else
      :down
    end
  end

  @impl Ecto.Adapter.Storage
  def storage_up(options) do
    storage_up_with_path(Keyword.get(options, :database), Keyword.get(options, :journal_mode, :wal))
  end

  @impl Ecto.Adapter.Migration
  def supports_ddl_transaction?(), do: false

  @impl Ecto.Adapter.Migration
  def lock_for_migrations(_meta, _options, fun) do
    fun.()
  end

  @impl Ecto.Adapter.Structure
  def structure_dump(default, config) do
    path = config[:dump_path] || Path.join(default, "structure.sql")

    with {:ok, contents} <- dump_schema(config),
         {:ok, versions} <- dump_versions(config) do
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents <> versions)
      {:ok, path}
    else
      err -> err
    end
  end

  @impl Ecto.Adapter.Structure
  def structure_load(default, config) do
    path = config[:dump_path] || Path.join(default, "structure.sql")

    case run_with_cmd("sqlite3", [config[:database], ".read #{path}"]) do
      {_output, 0} -> {:ok, path}
      {output, _} -> {:error, output}
    end
  end

  ##
  ## Loaders
  ##

  @impl Ecto.Adapter
  def loaders(:boolean, type) do
    [&Codec.bool_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:naive_datetime_usec, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:utc_datetime_usec, type) do
    [&Codec.datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:utc_datetime, type) do
    [&Codec.datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:naive_datetime, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:datetime, type) do
    [&Codec.datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:date, type) do
    [&Codec.date_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders({:map, _}, type) do
    [&Codec.json_decode/1, &Ecto.Type.embedded_load(type, &1, :json)]
  end

  @impl Ecto.Adapter
  def loaders({:array, _}, type) do
    [&Codec.json_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:map, type) do
    [&Codec.json_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:float, type) do
    [&Codec.float_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:decimal, type) do
    [&Codec.decimal_decode/1, type]
  end

  # when we have an e.g., max(created_date) function
  # Ecto does not truly know the return type, hence :maybe
  # see Ecto.Query.Planner.collect_fields
  @impl Ecto.Adapter
  def loaders({:maybe, :naive_datetime}, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(_, type) do
    [type]
  end

  ##
  ## Dumpers
  ##

  @impl Ecto.Adapter
  def dumpers(:binary, type) do
    [type, &Codec.blob_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:boolean, type) do
    [type, &Codec.bool_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:decimal, type) do
    [type, &Codec.decimal_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:time, type) do
    [type, &Codec.time_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:naive_datetime, type) do
    [type, &Codec.naive_datetime_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers({:array, _}, type) do
    [type, &Codec.json_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers({:map, _}, type) do
    [&Ecto.Type.embedded_dump(type, &1, :json), &Codec.json_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:map, type) do
    [type, &Codec.json_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(_primitive, type) do
    [type]
  end

  ##
  ## HELPERS
  ##

  defp storage_up_with_path(nil, _) do
    raise ArgumentError,
          """
          No SQLite database path specified. Please check the configuration for your Repo.
          Your config/*.exs file should have something like this in it:

            config :my_app, MyApp.Repo,
              adapter: Ecto.Adapters.SQLite3,
              database: "/path/to/sqlite/database"
          """
  end

  defp storage_up_with_path(db_path, journal_mode) do
    if File.exists?(db_path) do
      {:error, :already_up}
    else
      db_path |> Path.dirname() |> File.mkdir_p!()
      {:ok, db} = Exqlite.Sqlite3.open(db_path)
      :ok = Exqlite.Sqlite3.execute(db, "PRAGMA JOURNAL_MODE = #{journal_mode}")
      :ok = Exqlite.Sqlite3.close(db)
    end
  end

  defp dump_versions(config) do
    table = config[:migration_source] || "schema_migrations"

    # `.dump` command also returns CREATE TABLE which will clash with CREATE we already run in dump_schema
    # So we set mode to insert which makes every SELECT statement to issue the result
    # as the INSERT statements instead of pure text data.
    case run_with_cmd("sqlite3", [
           config[:database],
           ".mode insert #{table}",
           "SELECT * FROM #{table}"
         ]) do
      {output, 0} -> {:ok, output}
      {output, _} -> {:error, output}
    end
  end

  defp dump_schema(config) do
    case run_with_cmd("sqlite3", [config[:database], ".schema"]) do
      {output, 0} -> {:ok, output}
      {output, _} -> {:error, output}
    end
  end

  defp run_with_cmd(cmd, args) do
    unless System.find_executable(cmd) do
      raise "could not find executable `#{cmd}` in path, " <>
              "please guarantee it is available before running ecto commands"
    end

    System.cmd(cmd, args, stderr_to_stdout: true)
  end
end
