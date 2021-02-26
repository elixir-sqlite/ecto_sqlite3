defmodule Exqlite.Connection do
  @moduledoc """
  This module imlements connection details as defined in DBProtocol.

  ## Attributes

  - `db` - The sqlite3 database reference.
  - `path` - The path that was used to open.
  - `transaction_status` - The status of the connection. Can be `:idle` or `:transaction`.
  - `queries` - The `:ets` cache of prepared queries.

  ## Unknowns

  - How are pooled connections going to work? Since sqlite3 doesn't allow for
    simultaneous access. We would need to check if the write ahead log is
    enabled on the database. We can't assume and set the WAL pragma because the
    database may be stored on a network volume which would cause potential
    issues.

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
  alias Exqlite.Queries

  defstruct [
    :db,
    :path,
    :transaction_status,
    :queries
  ]

  @type t() :: %__MODULE__{
          db: Sqlite3.db(),
          path: String.t(),
          transaction_status: :idle | :transaction,
          queries: Queries.t()
        }

  @impl true
  @doc """
  Initializes the Ecto Exqlite adapter.

  Allowed options:

    - `database` - The database to the database. In memory databses are allowed. Use
      `:memory` or `":memory:"`.
  """
  def connect(opts) do
    database = Keyword.get(opts, :database)

    case database do
      nil ->
        {:error,
         %Error{
           message: """
           You must provide a :database to the database. \
           Example: connect(database: "./") or connect(database: :memory)\
           """
         }}

      :memory ->
        do_connect(":memory:")

      _ ->
        do_connect(database)
    end
  end

  @impl true
  def disconnect(_err, %__MODULE__{db: db, queries: queries}) do
    Queries.delete(queries)

    case Sqlite3.close(db) do
      :ok -> :ok
      {:error, reason} -> {:error, %Error{message: reason}}
    end
  end

  @impl true
  def checkin(state), do: {:ok, state}

  @impl true
  def checkout(state), do: {:ok, state}

  @impl true
  def ping(state), do: {:ok, state}

  ##
  ## Handlers
  ##

  @impl true
  def handle_prepare(%Query{} = query, _opts, state), do: prepare(query, state)

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    with {:ok, query, state} <- prepare(query, state) do
      execute(:execute, query, params, state)
    end
  end

  @doc """
  Begin a transaction.

  For full info refer to sqlite docs: https://sqlite.org/lang_transaction.html

  Note: default transaction mode is DEFERRED.
  """
  @impl true
  def handle_begin(options, %{transaction_status: transaction_status} = state) do
    # TODO: This doesn't handle more than 2 levels of transactions.
    #
    # One possible solution would be to just track the number of open
    # transactions and use that for driving the transaction status being idle or
    # in a transaction.
    #
    # I do not know why the other official adapters do not track this and just
    # append level on the savepoint. Instead the rollbacks would just completely
    # revert the issues when it may be desirable to fix something while in the
    # transaction and then commit.
    #
    case Keyword.get(options, :mode, :deferred) do
      :deferred when transaction_status == :idle ->
        handle_transaction(:begin, "BEGIN TRANSACTION", state)

      :immediate when transaction_status == :idle ->
        handle_transaction(:begin, "BEGIN IMMEDIATE TRANSACTION", state)

      :exclusive when transaction_status == :idle ->
        handle_transaction(:begin, "BEGIN EXCLUSIVE TRANSACTION", state)

      mode
      when mode in [:deferred, :immediate, :exclusive, :savepoint] and
             transaction_status == :transaction ->
        handle_transaction(:begin, "SAVEPOINT exqlite_savepoint", state)
    end
  end

  @impl true
  def handle_commit(options, %{transaction_status: transaction_status} = state) do
    case Keyword.get(options, :mode, :deferred) do
      :savepoint when transaction_status == :transaction ->
        handle_transaction(:commit, "RELEASE SAVEPOINT exqlite_savepoint", state)

      mode
      when mode in [:deferred, :immediate, :exclusive] and
             transaction_status == :transaction ->
        handle_transaction(:commit, "COMMIT", state)
    end
  end

  @impl true
  def handle_rollback(options, %{transaction_status: transaction_status} = state) do
    case Keyword.get(options, :mode, :deferred) do
      :savepoint when transaction_status == :transaction ->
        with {:ok, _result, state} <-
               handle_transaction(
                 :rollback,
                 "ROLLBACK TO SAVEPOINT exqlite_savepoint",
                 state
               ) do
          handle_transaction(:rollback, "RELEASE SAVEPOINT exqlite_savepoint", state)
        end

      mode
      when mode in [:deferred, :immediate, :exclusive] and
             transaction_status == :transaction ->
        handle_transaction(:rollback, "ROLLBACK TRANSACTION", state)
    end
  end

  @doc """
  Close a query prepared by `c:handle_prepare/3` with the database. Return
  `{:ok, result, state}` on success and to continue,
  `{:error, exception, state}` to return an error and continue, or
  `{:disconnect, exception, state}` to return an error and disconnect.

  This callback is called in the client process.
  """
  @impl true
  def handle_close(query, _opts, state) do
    if query.name do
      # If the query was named, it will be cached more than likely, and we just
      # need to make sure it has the reference removed so it can be garbage
      # collected
      Queries.delete(state.queries, query.name)
    end

    {:ok, nil, state}
  end

  @impl true
  def handle_declare(%Query{} = query, params, _opts, state) do
    with {:ok, query} <- prepare_no_cache(query, state),
         {:ok, query} <- bind_params(query, params, state) do
      {:ok, query, query.ref, state}
    end
  end

  @impl true
  def handle_deallocate(%Query{} = _query, _cursor, _opts, state) do
    # We actually don't need to do anything about the cursor. Since it is a
    # prepared statement, it will be garbage collected by erlang when it loses
    # references.
    {:ok, nil, state}
  end

  @impl true
  def handle_fetch(%Query{} = _query, cursor, _opts, state) do
    case Sqlite3.step(state.db, cursor) do
      :done ->
        {:halt, [], state}
      {:row, row} ->
        {:cont, row, state}
      :busy ->
        {:error, %Error{message: "Database busy"}, state}
      {:error, reason} ->
        {:error, %Error{message: reason}, state}
    end
  end

  @impl true
  def handle_status(_opts, state) do
    {state.transaction_status, state}
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
          transaction_status: :idle,
          queries: Queries.new(__MODULE__)
        }

        {:ok, state}

      {:error, reason} ->
        {:error, %Exqlite.Error{message: reason}}
    end
  end

  # Attempt to retrieve the cached query, if it doesn't exist, we'll prepare one
  # and cache it for later.
  defp prepare(%Query{statement: statement, ref: nil} = query, state) do
    case Queries.get(state.queries, query) do
      nil ->
        case Sqlite3.prepare(state.db, IO.iodata_to_binary(statement)) do
          {:ok, ref} ->
            query = %{query | ref: ref}
            Queries.put(state.queries, query)
            {:ok, query, state}

          {:error, reason} ->
            {:error, %Error{message: reason}}
        end

      cached_query ->
        {:ok, cached_query, state}
    end
  end

  defp prepare(%Query{ref: ref} = query, state) when ref != nil do
    {:ok, query, state}
  end

  # Prepare a query and do not cache it.
  defp prepare_no_cache(%Query{statement: statement} = query, state) do
    case Sqlite3.prepare(state.db, statement) do
      {:ok, ref} ->
        {:ok, %{query | ref: ref}, state}

      {:error, reason} ->
        {:error, %Error{message: reason}}
    end
  end

  defp execute(call, %Query{} = query, params, state) do
    with {:ok, query} <- bind_params(query, params, state),
         {:ok, columns} <- Sqlite3.columns(state.db, query.ref),
         {:ok, rows} <- Sqlite3.fetch_all(state.db, query.ref) do
      {
        :ok,
        query,
        %Result{
          columns: columns,
          rows: rows,
          command: call,
          num_rows: Enum.count(rows)
        },
        state
      }
    else
      {:error, reason} ->
        {:error, %Error{message: reason}}
    end
  end

  defp bind_params(%Query{ref: ref} = query, params, state) when ref != nil do
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
      {:error, reason} -> {:error, %Error{message: reason}}
    end
  end

  defp handle_transaction(call, statement, state) do
    case Sqlite3.execute(state.db, statement) do
      :ok ->
        result = %Result{
          command: call,
          rows: [],
          columns: [],
        }

        {:ok, result, state}

      {:error, reason} ->
        {:error, %Error{message: reason}}
    end
  end
end
