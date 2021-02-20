defmodule Exqlite.Connection do

  @doc """
  This module imlements connection details as defined in DBProtocol.

  Notes:
    - we try to closely follow structure and naming convention of myxql.
    - sqlite thrives when there are many small conventions, so we may not implement
      some strategies employed by other adapters. See https://sqlite.org/np1queryprob.html
  """

  use DBConnection
  alias Exqlite.Sqlite3
  alias Exqlite.Error
  alias Exqlite.Result

  defstruct [
    :db
  ]

  @impl true
  def connect(opts) do
    path = Keyword.get(opts, :path)

    case path do
      nil ->
        {:error,
         %Error{
           message:
             "You must provide a :path to the database. Example: connect(path: \"./\") or connect(path: :memory)"
         }}

      _ ->
        do_connect(path)
    end
  end

  @impl true
  def disconnect(_reason, %__MODULE__{db: db}) do
    case Sqlite3.close(db) do
      :ok -> :ok
      {:error, reason} -> {:error, %Error{message: reason}}
    end
  end

  @impl true
  def checkin(state) do
    {:ok, state}
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

end
