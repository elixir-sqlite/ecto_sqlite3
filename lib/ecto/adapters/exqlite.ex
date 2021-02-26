defmodule Ecto.Adapters.Exqlite do
  use Ecto.Adapters.SQL,
    driver: :exqlite

  import String, only: [to_integer: 1]

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

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

  @impl true
  def supports_ddl_transaction?(), do: false

  @impl Ecto.Adapter.Structure
  def structure_dump(_default, _config) do
    # table = config[:migration_source] || "schema_migrations"
    # path  = config[:dump_path] || Path.join(default, "structure.sql")
    #
    # TODO: dump the database and select the migration versions
    #
    # with {:ok, versions} <- select_versions(table, config),
    #      {:ok, contents} <- dump(config),
    #      {:ok, contents} <- append_versions(table, versions, contents) do
    #   File.mkdir_p!(Path.dirname(path))
    #   File.write!(path, contents)
    #   {:ok, path}
    # end
    {:error, :not_implemented}
  end

  @impl Ecto.Adapter.Structure
  def structure_load(_default, _config) do
    # load the structure.sql file
    {:error, :not_implemented}
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
    [&bool_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:binary_id, type) do
    [Ecto.UUID, type]
  end

  @impl Ecto.Adapter
  def loaders(:utc_datetime, type) do
    [&date_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:naive_datetime, type) do
    [&date_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:datetime, type) do
    [&date_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders({:embed, _} = type, _) do
    [&json_decode/1, &Ecto.Type.embedded_load(type, &1, :json)]
  end

  @impl Ecto.Adapter
  def loaders({:map, _}, type) do
    [&json_decode/1, &Ecto.Type.embedded_load(type, &1, :json)]
  end

  @impl Ecto.Adapter
  def loaders({:array, _}, type) do
    [&json_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:map, type) do
    [&json_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(:float, type) do
    [&float_decode/1, type]
  end

  @impl Ecto.Adapter
  def loaders(_, type) do
    [type]
  end

  defp bool_decode(0), do: {:ok, false}
  defp bool_decode("0"), do: {:ok, false}
  defp bool_decode("FALSE"), do: {:ok, false}
  defp bool_decode(1), do: {:ok, true}
  defp bool_decode("1"), do: {:ok, true}
  defp bool_decode("TRUE"), do: {:ok, true}
  defp bool_decode(x), do: {:ok, x}

  defp date_decode(
         <<year::binary-size(4), "-", month::binary-size(2), "-", day::binary-size(2)>>
       ) do
    {:ok, {to_integer(year), to_integer(month), to_integer(day)}}
  end

  defp date_decode(
         <<year::binary-size(4), "-", month::binary-size(2), "-", day::binary-size(2),
           " ", hour::binary-size(2), ":", minute::binary-size(2), ":",
           second::binary-size(2), ".", microsecond::binary-size(6)>>
       ) do
    {:ok,
     {{to_integer(year), to_integer(month), to_integer(day)},
      {to_integer(hour), to_integer(minute), to_integer(second),
       to_integer(microsecond)}}}
  end

  defp date_decode(x), do: {:ok, x}

  defp json_decode(x) when is_binary(x),
    do: {:ok, Application.get_env(:ecto, :json_library).decode!(x)}

  defp json_decode(x),
    do: {:ok, x}

  defp float_decode(x) when is_integer(x), do: {:ok, x / 1}
  defp float_decode(x), do: {:ok, x}

  ##
  ## Dumpers
  ##

  @impl Ecto.Adapter
  def dumpers(:binary, type) do
    [type, &blob_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:binary_id, type) do
    [type, Ecto.UUID]
  end

  @impl Ecto.Adapter
  def dumpers(:boolean, type) do
    [type, &bool_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers({:embed, _} = type, _) do
    [&Ecto.Type.embedded_dump(type, &1, :json)]
  end

  @impl Ecto.Adapter
  def dumpers(:time, type) do
    [type, &time_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers(:naive_datetime, type) do
    [type, &naive_datetime_encode/1]
  end

  @impl Ecto.Adapter
  def dumpers({:in, sub}, {:in, sub}) do
    [{:array, sub}]
  end

  @impl Ecto.Adapter
  def dumpers(_primitive, type) do
    [type]
  end

  defp blob_encode(value), do: {:ok, {:blob, value}}

  defp bool_encode(false), do: {:ok, 0}
  defp bool_encode(true), do: {:ok, 1}

  defp time_encode(value) do
    {:ok, value}
  end

  defp naive_datetime_encode(value) do
    {:ok, NaiveDateTime.to_iso8601(value)}
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
end
