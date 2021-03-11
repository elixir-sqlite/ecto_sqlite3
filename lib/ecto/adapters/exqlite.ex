defmodule Ecto.Adapters.Exqlite do
  use Ecto.Adapters.SQL,
    driver: :exqlite

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

  alias Ecto.Adapters.Exqlite.Codec

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
    options
    |> Keyword.get(:database)
    |> storage_up_with_path()
  end

  @impl Ecto.Adapter.Migration
  def supports_ddl_transaction?(), do: false

  @impl Ecto.Adapter.Migration
  def lock_for_migrations(_meta, query, _options, fun) do
    fun.(query)
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

  @impl Ecto.Adapter.Schema
  def insert(adapter_meta, schema_meta, params, on_conflict, returning, opts) do
    %{source: source, prefix: prefix} = schema_meta
    {_, query_params, _} = on_conflict

    key = primary_key!(schema_meta, returning)
    {fields, values} = :lists.unzip(params)

    # Construct the insertion sql statement
    sql = @conn.insert(prefix, source, fields, [fields], on_conflict, [], [])

    # Build the query name we are going to pass on
    opts = [{:command, :insert} | opts]
    opts = [{:query_name, generate_cache_name(:insert, sql)} | opts]

    case Ecto.Adapters.SQL.query(adapter_meta, sql, values ++ query_params, opts) do
      {:ok, %{last_insert_id: rowid}} ->
        {:ok, last_insert_id(key, rowid)}

      {:error, err} ->
        case @conn.to_constraints(err, source: source) do
          [] -> raise err
          constraints -> {:invalid, constraints}
        end
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
  def loaders(:binary_id, type) do
    [Ecto.UUID, type]
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
  def loaders({:embed, _} = type, _) do
    [&Codec.json_decode/1, &Ecto.Type.embedded_load(type, &1, :json)]
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
  def dumpers(:binary_id, type) do
    [type, Ecto.UUID]
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
  def dumpers({:embed, _} = type, _) do
    [&Ecto.Type.embedded_dump(type, &1, :json)]
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
    [type, &Codec.json_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(_primitive, type) do
    [type]
  end

  ##
  ## HELPERS
  ##

  defp primary_key!(%{autogenerate_id: {_, key, _type}}, [key]), do: key
  defp primary_key!(_, []), do: nil

  defp primary_key!(%{schema: schema}, returning) do
    raise ArgumentError,
          "Sqlite3 does not support :read_after_writes in schemas for non-primary keys. " <>
            "The following fields in #{inspect(schema)} are tagged as such: #{
              inspect(returning)
            }"
  end

  defp last_insert_id(nil, _last_insert_id), do: []
  defp last_insert_id(_key, 0), do: []
  defp last_insert_id(key, last_insert_id), do: [{key, last_insert_id}]

  defp generate_cache_name(operation, sql) do
    digest = :crypto.hash(:sha, IO.iodata_to_binary(sql)) |> Base.encode16()
    "ecto_#{operation}_#{digest}"
  end

  defp storage_up_with_path(nil) do
    raise ArgumentError,
          """
          No SQLite database path specified. Please check the configuration for your Repo.
          Your config/*.exs file should have something like this in it:

            config :my_app, MyApp.Repo,
              adapter: Ecto.Adapters.Exqlite,
              database: "/path/to/sqlite/database"
          """
  end

  defp storage_up_with_path(db_path) do
    if File.exists?(db_path) do
      {:error, :already_up}
    else
      db_path |> Path.dirname() |> File.mkdir_p!()
      {:ok, db} = Exqlite.Sqlite3.open(db_path)
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
