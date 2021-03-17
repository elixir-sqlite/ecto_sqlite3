defmodule Exqlite.Sqlite3NIF do
  @moduledoc """
  This is the module where all of the NIF entry points reside. Calling this directly
  should be avoided unless you are aware of what you are doing.
  """

  @on_load :load_nifs

  @type db() :: reference()
  @type statement() :: reference()
  @type reason() :: :atom | String.Chars.t()

  def load_nifs() do
    path = :filename.join(:code.priv_dir(:exqlite), 'sqlite3_nif')
    :erlang.load_nif(path, 0)
  end

  @spec open(String.Chars.t()) :: {:ok, db()} | {:error, reason()}
  def open(_path), do: :erlang.nif_error(:not_loaded)

  @spec close(db()) :: :ok | {:error, reason()}
  def close(_conn), do: :erlang.nif_error(:not_loaded)

  @spec execute(db(), String.Chars.t()) :: :ok | {:error, reason()}
  def execute(_conn, _sql), do: :erlang.nif_error(:not_loaded)

  @spec changes(db()) :: {:ok, integer()}
  def changes(_conn), do: :erlang.nif_error(:not_loaded)

  @spec prepare(db(), String.Chars.t()) :: {:ok, statement()} | {:error, reason()}
  def prepare(_conn, _sql), do: :erlang.nif_error(:not_loaded)

  @spec bind(db(), statement(), []) ::
          :ok | {:error, reason()} | {:error, {atom(), any()}}
  def bind(_conn, _statement, _args), do: :erlang.nif_error(:not_loaded)

  @spec step(db(), statement()) :: :done | :busy | {:row, []}
  def step(_conn, _statement), do: :erlang.nif_error(:not_loaded)

  @spec columns(db(), statement()) :: {:ok, []} | {:error, reason()}
  def columns(_conn, _statement), do: :erlang.nif_error(:not_loaded)

  @spec last_insert_rowid(db()) :: {:ok, integer()}
  def last_insert_rowid(_conn), do: :erlang.nif_error(:not_loaded)

  @spec transaction_status(db()) :: {:ok, :idle | :transaction}
  def transaction_status(_conn), do: :erlang.nif_error(:not_loaded)

  # TODO: add statement inspection tooling https://sqlite.org/c3ref/expanded_sql.html
end
