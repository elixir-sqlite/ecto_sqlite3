defmodule Ecto.Adapters.Exqlite do
  use Ecto.Adapters.SQL,
    driver: :exqlite

  import String, only: [to_integer: 1]

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

  @impl true
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

  @impl true
  def storage_status(options) do
    db_path = Keyword.fetch!(options, :database)

    if File.exists?(db_path) do
      :up
    else
      :down
    end
  end

  @impl true
  def storage_up(options) do
    db_path = Keyword.fetch!(options, :database)

    Path.dirname(db_path) |> File.mkdir_p!()
    {:ok, db} = Exqlite.Sqlite3.open(db_path)
    :ok = Exqlite.Sqlite3.close(db)
  end

  @impl true
  def supports_ddl_transaction?(), do: true

  @impl true
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

  @impl true
  def structure_load(_default, _config) do
    # load the structure.sql file
    {:error, :not_implemented}
  end

  @impl true
  def loaders(:boolean, type), do: [&bool_decode/1, type]
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(:utc_datetime, type), do: [&date_decode/1, type]
  def loaders(:naive_datetime, type), do: [&date_decode/1, type]

  def loaders({:embed, _} = type, _),
    do: [&json_decode/1, &Ecto.Adapters.SQL.load_embed(type, &1)]

  def loaders(:map, type), do: [&json_decode/1, type]
  def loaders({:map, _}, type), do: [&json_decode/1, type]
  def loaders({:array, _}, type), do: [&json_decode/1, type]
  def loaders(:float, type), do: [&float_decode/1, type]

  def loaders(_primitive, type) do
    [type]
  end

  defp bool_decode(0), do: {:ok, false}
  defp bool_decode(1), do: {:ok, true}
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

  @impl true
  def dumpers(:binary, type), do: [type, &blob_encode/1]
  def dumpers(:binary_id, type), do: [type, Ecto.UUID]
  def dumpers(:boolean, type), do: [type, &bool_encode/1]
  def dumpers({:embed, _} = type, _), do: [&Ecto.Adapters.SQL.dump_embed(type, &1)]
  def dumpers(:time, type), do: [type, &time_encode/1]
  def dumpers(:naive_datetime, type), do: [type, &naive_datetime_encode/1]
  def dumpers(_primitive, type), do: [type]

  defp blob_encode(value), do: {:ok, {:blob, value}}

  defp bool_encode(false), do: {:ok, 0}
  defp bool_encode(true), do: {:ok, 1}

  defp time_encode(value) do
    {:ok, value}
  end

  defp naive_datetime_encode(value) do
    {:ok, NaiveDateTime.to_iso8601(value)}
  end
end
