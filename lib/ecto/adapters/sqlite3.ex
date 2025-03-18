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
    * `:default_transaction_mode` - one of `:deferred` (default), `:immediate`, or
      `:exclusive`. If a mode is not specified in a call to `Repo.transaction/2`, this
      will be the default transaction mode.
    * `:journal_mode` - Sets the journal mode for the sqlite connection. Can be one of
      the following `:delete`, `:truncate`, `:persist`, `:memory`, `:wal`, or `:off`.
      Defaults to `:wal`.
    * `:temp_store` - Sets the storage used for temporary tables. Default is `:default`.
      Allowed values are `:default`, `:file`, `:memory`.
    * `:synchronous` - Can be `:extra`, `:full`, `:normal`, or `:off`. Defaults to `:normal`.
    * `:foreign_keys` - Sets if foreign key checks should be enforced or not. Can be
      `:on` or `:off`. Default is `:on`.
    * `:cache_size` - Sets the cache size to be used for the connection. This is an odd
      setting as a positive value is the number of pages in memory to use and a negative
      value is the size in kilobytes to use. Default is `-64000`.
    * `:cache_spill` - The cache_spill pragma enables or disables the ability of the
      pager to spill dirty cache pages to the database file in the middle of a
      transaction. By default it is `:on`, and for most applications, it should remain
      so.
    * `:case_sensitive_like` - whether LIKE is case-sensitive or not. Can be
      `:off` or `:on`. Defaults to `:off`.
    * `:auto_vacuum` - Defaults to `:none`. Can be `:none`, `:full` or `:incremental`.
      Depending on the database size, `:incremental` may be beneficial.
    * `:locking_mode` - Defaults to `:normal`. Allowed values are `:normal` or
      `:exclusive`. See [sqlite documentation][1] for more information.
    * `:secure_delete` - Defaults to `:off`. Can be `:off` or `:on`. If `:on`, it will
      cause SQLite3 to overwrite records that were deleted with zeros.
    * `:wal_auto_check_point` - Sets the write-ahead log auto-checkpoint interval.
      Default is `1000`. Setting the auto-checkpoint size to zero or a negative value
      turns auto-checkpointing off.
    * `:busy_timeout` - Sets the busy timeout in milliseconds for a connection.
      Default is `2000`.
    * `:pool_size` - the size of the connection pool. Defaults to `5`.
    * `:binary_id_type` - Defaults to `:string`. Determines how binary IDs are stored in
      the database and the type of `:binary_id` columns. See the
      [section on binary ID types](#module-binary-id-types) for more details.
    * `:uuid_type` - Defaults to `:string`. Determines the type of `:uuid` columns.
      Possible values and column types are the same as for
      [binary IDs](#module-binary-id-types).
    * `:map_type` - Defaults to `:string`. Determines the type of `:map` columns.
      Set to `:binary` to use the [JSONB](https://sqlite.org/jsonb.html)
      storage format.
    * `:array_type` - Defaults to `:string`. Determines the type of `:array` columns.
      Arrays are serialized using JSON. Set to `:binary` to use the
      [JSONB](https://sqlite.org/jsonb.html) storage format.
    * `:datetime_type` - Defaults to `:iso8601`. Determines how datetime fields are
      stored in the database. The allowed values are `:iso8601` and `:text_datetime`.
      `:iso8601` corresponds to a string of the form `YYYY-MM-DDThh:mm:ss` and
      `:text_datetime` corresponds to a string of the form `YYYY-MM-DD hh:mm:ss`
    * `:load_extensions` - list of paths identifying extensions to load. Defaults to `[]`.
       The provided list will be merged with the global extensions list, set on
       `:exqlite, :load_extensions`. Be aware that the path should handle pointing to a
       library compiled for the current architecture. See `Exqlite.Connection.connect/1`
       for more.

  For more information about the options above, see [sqlite documentation][1]

  ### Differences between SQLite and Ecto SQLite defaults

  For the most part, the defaults we provide above match the defaults that SQLite usually
  ships with. However, SQLite has conservative defaults due to its need to be strictly
  backwards compatible, so some of them do not necessarily match "best practices". Below
  are the defaults we provide above that differ from the normal SQLite defaults, along
  with rationale.

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

  ### Binary ID types

  The `:binary_id_type` configuration option allows configuring how `:binary_id` fields
  are stored in the database as well as the type of the column in which these IDs will
  be stored. The possible values are:

  * `:string` - IDs are stored as strings, and the type of the column is `TEXT`. This is
    the default.
  * `:binary` - IDs are stored in their raw binary form, and the type of the column is `BLOB`.

  The main differences between the two formats are as follows:
  * When stored as binary, UUIDs require much less space in the database. IDs stored as
    strings require 36 bytes each, while IDs stored as binary only require 16 bytes.
  * Because SQLite does not have a dedicated UUID type, most clients cannot represent
    UUIDs stored as binary in a human readable format. Therefore, IDs stored as strings
    may be easier to work with if manual manipulation is required.

  ## Limitations and caveats

  There are some limitations when using Ecto with SQLite that one needs
  to be aware of. The ones listed below are specific to Ecto usage, but it
  is encouraged to also view the guidance on [when to use SQLite][4] provided
  by the SQLite documentation, as well.

  ### In memory robustness

  When using the Ecto SQLite3 adapter with the database set to `:memory` it
  is possible that a crash in a process performing a query in the Repo will
  cause the database to be destroyed. This makes the `:memory` function
  unsuitable when it is expected to survive potential process crashes (for
  example a crash in a Phoenix request)

  ### Async Sandbox testing

  The Ecto SQLite3 adapter does not support async tests when used with
  `Ecto.Adapters.SQL.Sandbox`. This is due to SQLite only allowing up one write
  transaction at a time, which often does not work with the Sandbox approach of wrapping
  each test in a transaction.

  ### LIKE match on BLOB columns

  We have the `SQLITE_LIKE_DOESNT_MATCH_BLOBS` compile-time definition option set to true,
  as [recommended by SQLite][3]. This means you cannot do `LIKE` queries on `BLOB` columns.

  ### Case sensitivity

  Case sensitivity for `LIKE` is off by default, and controlled by the `:case_sensitive_like`
  option outlined above.

  However, for equality comparison, case sensitivity is always _on_.
  If you want to make a column not be case sensitive, for email storage for example, you
  can make it case insensitive by using the [`COLLATE NOCASE`][6] option in SQLite. This
  is configured via the `:collate` option.

  So instead of:

      add :email, :string

  You would do:

      add :email, :string, collate: :nocase

  ### Check constraints

  SQLite3 supports specifying check constraints on the table or on the column definition.
  We currently only support adding a check constraint via a column definition, since the
  table definition approach only works at table-creation time and cannot be added at
  table-alter time. You can see more information in the SQLite3
  [CREATE TABLE documentation](https://sqlite.org/lang_createtable.html).

  Because of this, you cannot add a constraint via the normal `Ecto.Migration.constraint/3`
  method, as that operates via `ALTER TABLE ADD CONSTRAINT`, and this type of `ALTER TABLE`
  operation SQLite3 does not support. You can however get the full functionality by
  adding a constraint at the column level, specifying the name and expression. Per the
  SQLite3 documentation, there is no _functional_ difference between a column or table
  constraint.

  Thus, adding a check constraint for a new column is as simple as:

      add :email, :string, check: %{name: "test_constraint", expr: "email != 'test@example.com'"}

  ### Handling foreign key constraints in changesets

  Unfortunately, unlike other databases, SQLite3 does not provide the precise name of
  the constraint violated, but only the columns within that constraint (if it provides
  any information at all). Because of this, changeset functions like
  `Ecto.Changeset.foreign_key_constraint/3` may not work at all.

  This is because the above functions depend on the Ecto Adapter returning the name of
  the violated constraint, which you annotate in your changeset so that Ecto can convert
  the constraint violation into the correct updated changeset when the constraint is hit
  during a `c:Ecto.Repo.update/2` or `c:Ecto.Repo.insert/2` operation. Since we cannot
  get the name of the violated constraint back from SQLite3 at `INSERT` or `UPDATE`
  time, there is no way to effectively use these changeset functions. This is a SQLite3
  limitation.

  See [this GitHub issue](https://github.com/elixir-sqlite/ecto_sqlite3/issues/42) for
  more details.

  ### Schemaless queries

  Using [schemaless Ecto queries][7] will not work well with SQLite. This is because
  the Ecto SQLite adapter relies heavily on the schema to support a rich array of Elixir
  types, despite the fact SQLite only has [five storage classes][5]. The query will still
  work and return data, but you will need to do this mapping on your own.

  ### Transaction mode

  By default, [SQLite transactions][8] run in `DEFERRED` mode. However, in 
  web applications with a balanced load of reads and writes, using  `IMMEDIATE` 
  mode may yield better performance.

  Here are several ways to specify a different transaction mode:

  **Pass `mode: :immediate` to `Repo.transaction/2`:** Use this approach to set 
  the transaction mode for individual transactions.

      Multi.new()
      |> Multi.run(:example, fn _repo, _changes_so_far ->
        # ... do some work ...
      end)
      |> Repo.transaction(mode: :immediate)

  **Define custom transaction functions:** Create wrappers, such as 
  `Repo.immediate_transaction/2` or `Repo.deferred_transaction/2`, to easily 
  apply different modes where needed.

      defmodule MyApp.Repo do
        def immediate_transaction(fun_or_multi) do
          transaction(fun_or_multi, mode: :immediate)
        end

        def deferred_transaction(fun_or_multi) do
          transaction(fun_or_multi, mode: :deferred)
        end
      end

  **Set a global default:** Configure `:default_transaction_mode` to apply a 
  preferred mode for all transactions, unless explicitly passed a different
  `:mode` to `Repo.transaction/2`.

      config :my_app, MyApp.Repo,
        database: "path/to/my/database.db",
        default_transaction_mode: :immediate

  [3]: https://www.sqlite.org/compile.html
  [4]: https://www.sqlite.org/whentouse.html
  [5]: https://www.sqlite.org/datatype3.html
  [6]: https://www.sqlite.org/datatype3.html#collating_sequences
  [7]: https://hexdocs.pm/ecto/schemaless-queries.html
  [8]: https://www.sqlite.org/lang_transaction.html#deferred_immediate_and_exclusive_transactions
  """

  use Ecto.Adapters.SQL,
    driver: :exqlite

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

  alias Ecto.Adapters.SQLite3.Codec

  @impl Ecto.Adapter.Storage
  def storage_down(options) do
    db_path = Keyword.fetch!(options, :database)

    case File.rm(db_path) do
      :ok ->
        File.rm(db_path <> "-shm")
        File.rm(db_path <> "-wal")
        :ok

      _otherwise ->
        {:error, :already_down}
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
    database = Keyword.get(options, :database)
    pool_size = Keyword.get(options, :pool_size)

    cond do
      is_nil(database) ->
        raise ArgumentError,
              """
              No SQLite database path specified. Please check the configuration for your Repo.
              Your config/*.exs file should have something like this in it:

                config :my_app, MyApp.Repo,
                  adapter: Ecto.Adapters.SQLite3,
                  database: "/path/to/sqlite/database"
              """

      File.exists?(database) ->
        {:error, :already_up}

      database == ":memory:" && pool_size != 1 ->
        raise ArgumentError, """
        In memory databases must have a pool_size of 1
        """

      true ->
        {:ok, state} = Exqlite.Connection.connect(options)
        :ok = Exqlite.Connection.disconnect(:normal, state)
    end
  end

  @impl Ecto.Adapter.Migration
  def supports_ddl_transaction?, do: true

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

  @impl Ecto.Adapter.Structure
  def dump_cmd(args, opts \\ [], config) when is_list(config) and is_list(args) do
    run_with_cmd("sqlite3", ["-init", "/dev/null", config[:database] | args], opts)
  end

  @impl Ecto.Adapter.Schema
  def autogenerate(:id), do: nil
  def autogenerate(:embed_id), do: Ecto.UUID.generate()

  def autogenerate(:binary_id) do
    case Application.get_env(:ecto_sqlite3, :binary_id_type, :string) do
      :string -> Ecto.UUID.generate()
      :binary -> Ecto.UUID.bingenerate()
    end
  end

  ##
  ## Loaders
  ##

  @default_datetime_type :iso8601

  @impl Ecto.Adapter
  def loaders(:boolean, type) do
    [&Codec.bool_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:naive_datetime_usec, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:time, type) do
    [&Codec.time_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:utc_datetime_usec, type) do
    [&Codec.utc_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:utc_datetime, type) do
    [&Codec.utc_datetime_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:naive_datetime, type) do
    [&Codec.naive_datetime_decode/1, type]
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

  @impl Ecto.Adapter
  def loaders(:binary_id, type) do
    case Application.get_env(:ecto_sqlite3, :binary_id_type, :string) do
      :string -> [type]
      :binary -> [Ecto.UUID, type]
    end
  end

  @impl Ecto.Adapter
  def loaders(:uuid, type) do
    case Application.get_env(:ecto_sqlite3, :uuid_type, :string) do
      :string -> []
      :binary -> [type]
    end
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
  def dumpers(:binary_id, type) do
    case Application.get_env(:ecto_sqlite3, :binary_id_type, :string) do
      :string -> [type]
      :binary -> [type, Ecto.UUID]
    end
  end

  @impl Ecto.Adapter
  def dumpers(:uuid, type) do
    case Application.get_env(:ecto_sqlite3, :uuid_type, :string) do
      :string -> []
      :binary -> [type]
    end
  end

  @impl Ecto.Adapter
  def dumpers(:time, type) do
    [type, &Codec.time_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:utc_datetime, type) do
    dt_type = Application.get_env(:ecto_sqlite3, :datetime_type, @default_datetime_type)
    [type, &Codec.utc_datetime_encode(&1, dt_type)]
  end

  @impl Ecto.Adapter
  def dumpers(:utc_datetime_usec, type) do
    dt_type = Application.get_env(:ecto_sqlite3, :datetime_type, @default_datetime_type)
    [type, &Codec.utc_datetime_encode(&1, dt_type)]
  end

  @impl Ecto.Adapter
  def dumpers(:naive_datetime, type) do
    dt_type = Application.get_env(:ecto_sqlite3, :datetime_type, @default_datetime_type)
    [type, &Codec.naive_datetime_encode(&1, dt_type)]
  end

  @impl Ecto.Adapter
  def dumpers(:naive_datetime_usec, type) do
    dt_type = Application.get_env(:ecto_sqlite3, :datetime_type, @default_datetime_type)
    [type, &Codec.naive_datetime_encode(&1, dt_type)]
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

  defp run_with_cmd(cmd, args, cmd_opts \\ []) do
    unless System.find_executable(cmd) do
      raise "could not find executable `#{cmd}` in path, " <>
              "please guarantee it is available before running ecto commands"
    end

    cmd_opts = Keyword.put_new(cmd_opts, :stderr_to_stdout, true)

    System.cmd(cmd, args, cmd_opts)
  end
end
