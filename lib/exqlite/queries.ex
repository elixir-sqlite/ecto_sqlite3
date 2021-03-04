defmodule Exqlite.Queries do
  @moduledoc """
  The interface to manage cached prepared queries.
  """

  #
  # TODO: We should probably do some tracking on the number of statements being
  #       generated and culling the oldest cached value (LRU). In its current
  #       implementation, this could just have a run away memory leak if we are
  #       not careful.
  #

  alias Exqlite.Query

  defstruct [:queries, :timestamps, :limit]

  @type t() :: %__MODULE__{
          queries: ETS.Set.t(),
          timestamps: ETS.Set.t(),
          limit: integer()
        }

  @type reason() :: String.t() | atom()

  @doc """
  Constructs a new prepared query cache with the specified limit. The cache uses
  a least recently used caching mechanism.
  """
  @spec new(atom()) :: t()
  def new(limit \\ 50) do
    with {:ok, queries} <- ETS.Set.new(protection: :public),
         {:ok, timestamps} <- ETS.Set.new(ordered: true, protection: :public) do
      %__MODULE__{
        queries: queries,
        timestamps: timestamps,
        limit: limit
      }
    end
  end

  @spec put(t(), Query.t()) :: {:ok, t()}
  def put(cache, %Query{name: ""}), do: {:ok, cache}

  @spec put(t(), Query.t()) :: {:ok, t()}
  def put(cache, %Query{name: nil}), do: {:ok, cache}

  @spec put(t(), Query.t()) :: {:ok, t()}
  def put(cache, %Query{ref: nil}), do: {:ok, cache}

  @spec put(t(), Query.t()) :: {:ok, t()} | {:error, reason()}
  def put(cache, %Query{name: query_name, ref: ref}) do
    with timestamp <- current_timestamp(),
         {:ok, timestamps} <- ETS.Set.put(cache.timestamps, {timestamp, query_name}),
         {:ok, queries} <- ETS.Set.put(cache.queries, {query_name, timestamp, ref}) do
      clean(%{cache | timestamps: timestamps, queries: queries})
    end
  end

  @spec destroy(nil) :: :ok
  def destroy(nil), do: :ok

  @doc """
  Completely delete the cache.
  """
  @spec destroy(t()) :: :ok
  def destroy(cache) do
    with {:ok, _} <- ETS.Set.delete(cache.queries),
         {:ok, _} <- ETS.Set.delete(cache.timestamps) do
      :ok
    end
  end

  @spec delete(t(), Query.t()) :: {:ok, t()}
  def delete(cache, %Query{name: nil}), do: {:ok, cache}

  @spec delete(t(), Query.t()) :: {:ok, t()}
  def delete(cache, %Query{name: ""}), do: {:ok, cache}

  @spec delete(t(), Query.t()) :: {:ok, t()} | {:error, reason()}
  def delete(cache, %Query{name: query_name}) do
    with {:ok, {_, timestamp, _}} <- ETS.Set.get(cache.queries, query_name),
         {:ok, timestamps} <- ETS.Set.delete(cache.timestamps, timestamp),
         {:ok, queries} <- ETS.Set.delete(cache.queries, query_name) do
      {:ok, %{cache | timestamps: timestamps, queries: queries}}
    end
  end

  @spec get(t(), Query.t()) :: {:ok, nil}
  def get(_cache, %Query{name: nil}), do: {:ok, nil}

  @spec get(t(), Query.t()) :: {:ok, nil}
  def get(_cache, %Query{name: ""}), do: {:ok, nil}

  @doc """
  Gets an existing prepared query if it exists. Otherwise `nil` is returned.
  """
  @spec get(t(), Query.t()) :: {:ok, Query.t() | nil} | {:error, reason()}
  def get(cache, %Query{name: query_name} = query) do
    with {:ok, {_, timestamp, ref}} <- ETS.Set.get(cache.queries, query_name),
         {:ok, _} <- ETS.Set.delete(cache.timestamps, timestamp),
         timestamp <- current_timestamp(),
         {:ok, _} <- ETS.Set.put(cache.timestamps, {timestamp, query_name}),
         {:ok, _} <- ETS.Set.put(cache.queries, {query_name, timestamp, ref}) do
      {:ok, %{query | ref: ref}}
    else
      {:ok, nil} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown_error}
    end
  end

  @doc """
  Clears all of the cached prepared statements.
  """
  @spec clear(t()) :: {:ok, t()}
  def clear(cache) do
    with {:ok, queries} <- ETS.Set.delete_all(cache.queries),
         {:ok, timestamps} <- ETS.Set.delete_all(cache.timestamps) do
      {:ok, %{cache | queries: queries, timestamps: timestamps}}
    end
  end

  @spec size(t()) :: integer()
  def size(cache) do
    case ETS.Set.info(cache.queries, true) do
      {:ok, info} -> Keyword.get(info, :size, 0)
      _ -> 0
    end
  end

  ##
  ## Helpers
  ##

  defp current_timestamp(), do: :erlang.unique_integer([:monotonic])

  defp clean(cache) do
    if size(cache) > cache.limit do
      with {:ok, timestamp} <- ETS.Set.first(cache.timestamps),
           {:ok, {_, query_name}} <- ETS.Set.get(cache.timestamps, timestamp),
           {:ok, timestamps} <- ETS.Set.delete(cache.timestamps, timestamp),
           {:ok, queries} <- ETS.Set.delete(cache.queries, query_name) do
        {:ok, %{cache | timestamps: timestamps, queries: queries}}
      else
        {:ok, nil} -> {:ok, cache}
        _ -> {:ok, cache}
      end
    else
      {:ok, cache}
    end
  end
end
