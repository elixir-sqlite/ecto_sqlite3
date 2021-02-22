defmodule Ecto.Integration.Repo do
  defmacro __using__(opts) do
    quote do
      use Ecto.Repo, unquote(opts)

      @query_event __MODULE__
                   |> Module.split()
                   |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
                   |> Kernel.++([:query])

      def init(_, opts) do
        fun = &Ecto.Integration.Repo.handle_event/4
        :telemetry.attach_many(__MODULE__, [[:custom], @query_event], fun, :ok)
        {:ok, opts}
      end
    end
  end

  def handle_event(event, latency, metadata, _config) do
    handler = Process.delete(:telemetry) || fn _, _, _ -> :ok end
    handler.(event, latency, metadata)
  end
end

defmodule Ecto.Integration.TestRepo do
  use Ecto.Integration.Repo, otp_app: :ecto_sql, adapter: Ecto.Adapters.Exqlite

  def create_prefix(prefix) do
    "create database #{prefix}"
  end

  def drop_prefix(prefix) do
    "drop database #{prefix}"
  end

  def uuid do
    Ecto.UUID
  end
end

defmodule Ecto.Integration.PoolRepo do
  use Ecto.Integration.Repo, otp_app: :ecto_sql, adapter: Ecto.Adapters.Exqlite
end
