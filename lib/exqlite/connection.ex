defmodule Exqlite.Connection do
  @moduledoc """
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
  alias Exqlite.Query

  defstruct [
    :db, :path
  ]

  @impl true
  def connect(opts) do
    path = Keyword.get(opts, :path)

    case path do
      nil ->
        {:error,
         %Error{
           message:
             ~s{You must provide a :path to the database. Example: connect(path: "./") or connect(path: :memory)}
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

  ### ----------------------------------
  #   handle_* implementations
  ### ----------------------------------

  @impl true
  def handle_prepare(%Query{} = query, _opts, state) do
    # TODO: we may want to cache prepared queries like Myxql does
    #       for now we just invoke sqlite directly
    prepare(query, state)
  end

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    with {:ok, query, state} <- maybe_prepare(query, state) do
      execute(query, params, state)
    end
  end

  @doc """
  Begin a transaction.

  For full info refer to sqlite docs: https://sqlite.org/lang_transaction.html

  Note: default transaction mode is DEFERRED.
  """
  @impl true
  def handle_begin(opts, state) do
    # TODO: track nested transactions.
    #       sqlite doesn't nest transactions with BEGIN... COMMIT...,
    #       use the SAVEPOINT and RELEASE commands.

    # TODO: handle/track SAVEPOINT
    case Keyword.get(opts, :mode, :deferred) do
      :immediate ->
        handle_transaction(:begin, "BEGIN IMMEDIATE TRANSACTION", state)

      :exclusive ->
        handle_transaction(:begin, "BEGIN EXCLUSIVE TRANSACTION", state)

      mode when mode in [nil, :deferred] ->
        handle_transaction(:begin, "BEGIN TRANSACTION", state)
    end
  end

  @impl true
  def handle_commit(_opts, state) do
    # TODO: once we handle SAVEPOINT, we need to handle RELEASE
    #       COMMIT TO
    #       Meanwhile we just COMMIT
    #       see https://sqlite.org/lang_transaction.html
    handle_transaction(:commit, "COMMIT", state)
  end

  @impl true
  def handle_rollback(_opts, state) do
    # TODO: once we handle SAVEPOINT, we need to handle ROLLBACK TO
    #       Meanwhile we just ROLLBACK
    #       see https://sqlite.org/lang_transaction.html
    handle_transaction(:rollback, "ROLLBACK", state)
  end

  ### ----------------------------------
  #     Internal functions and helpers
  ### ----------------------------------

  defp do_connect(path) do
    case Sqlite3.open(path) do
      {:ok, db} ->
        state = %__MODULE__{
          db: db,
          path: path,
        }

        {:ok, state}

      {:error, reason} ->
        {:error, %Exqlite.Error{message: reason}}
    end
  end

  defp maybe_prepare(%Query{ref: ref} = query, state) when ref != nil, do: {:ok, query, state}
  defp maybe_prepare(%Query{} = query, state), do: prepare(query, state)

  defp prepare(%Query{statement: statement} = query, state) do
    case Sqlite3.prepare(state.db, statement) do
      {:ok, ref} -> {:ok, %{query | ref: ref}, state}
      {:error, reason} -> {:error, %Error{message: reason}}
    end
  end

  defp execute(%Query{} = query, params, state) do
    with {:ok, query} <- bind_params(query, params, state) do
      do_execute(query, state, %Result{})
    end
  end

  defp do_execute(%Query{ref: ref} = query, state, %Result{} = result) do
    case Sqlite3.step(state.db, query.ref) do
      :done ->
        # TODO: this query may fail, we need to properly propagate this
        {:ok, columns} = Sqlite3.columns(state.db, ref)

        # TODO: this may fail, we need to properly propagate this
        Sqlite3.close(ref)
        {:ok, %{result | columns: columns}}

      {:row, row} ->
        # TODO: we need something better than simply appending rows
        do_execute(query, state, %{result | rows: result.rows ++ [row]})

      :busy ->
        {:error, %Error{message: "Database busy"}}
    end
  end

  defp bind_params(%Query{ref: ref} = query, params, state) do
    # TODO:
    #    - Add parameter translation to sqlite types. See e.g.
    #      https://github.com/elixir-sqlite/sqlitex/blob/master/lib/sqlitex/statement.ex#L274
    #    - Do we do anything special to distinguish the different types of
    #      parameters? See https://www.sqlite.org/lang_expr.html#varparam and
    #      https://www.sqlite.org/c3ref/bind_blob.html E.g. we can accept a map of params
    #      that binds values to named params. We can look up their indices via
    #      https://www.sqlite.org/c3ref/bind_parameter_index.html
    case Sqlite3.bind(state.db, ref, params) do
      :ok -> {:ok, query}
      {:error, {code, reason}} -> {:error, %Error{message: "#{reason}. Code: #{code}"}}
      {:error, reason} -> {:error, %Error{message: reason}}
    end
  end

  defp handle_transaction(call, statement, state) do
    case Sqlite3.execute(state.db, statement) do
      :ok ->
        result = %Result{
          command: call
        }

        # TODO: if we track transactions, update state here
        {:ok, statement, result, state}

      {:error, {code, reason}} ->
        {:error, %Error{message: "#{reason}. Code: #{code}"}}
    end
  end
end
