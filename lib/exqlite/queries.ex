defmodule Exqlite.Queries do
  @moduledoc """
  The interface to manage cached prepared queries.
  """

  alias Exqlite.Query

  @type cache :: :ets.tid()

  @spec new(atom()) :: cache()
  def new(name) do
    # TODO: Should this be set to :private?
    #
    # Ideally the only process that will be accessing this ets table would be
    # the connection that owns it.
    :ets.new(name, [:set, :public])
  end

  @spec put(cache(), Query.t()) :: :error
  def put(_cache, %Query{name: ""}), do: :error

  @spec put(cache(), Query.t()) :: :error
  def put(_cache, %Query{name: nil}), do: :error

  @spec put(cache(), Query.t()) :: :error
  def put(_cache, %Query{ref: nil}), do: :error

  @spec put(cache(), Query.t()) :: :ok | :error
  def put(cache, %Query{name: query_name, ref: ref}) do
    try do
      :ets.insert(cache, {query_name, {ref}})
    rescue
      ArgumentError -> :error
    else
      true -> :ok
    end
  end

  @spec delete(cache(), Query.t()) :: :error
  def delete(cache, %Query{name: nil}), do: :error

  @spec delete(cache(), Query.t()) :: :error
  def delete(cache, %Query{name: ""}), do: :error

  @spec delete(cache(), Query.t()) :: :ok | :error
  def delete(cache, %Query{name: query_name}) do
    try do
      :ets.delete(cache, query_name)
    rescue
      ArgumentError -> :error
    else
      true -> :ok
    end
  end

  @spec get(cache(), Query.t()) :: nil
  def get(cache, %Query{name: nil}), do: nil

  @spec get(cache(), Query.t()) :: nil
  def get(cache, %Query{name: ""}), do: nil

  @doc """
  Gets an existing prepared query if it exists. Otherwise `nil` is returned.
  """
  @spec get(cache(), Query.t()) :: Query.t() | nil
  def get(cache, %Query{name: query_name} = query) do
    try do
      :ets.lookup_element(cache, query_name, 2)
    rescue
      ArgumentError -> {:error, :not_found}
    else
      {ref} ->
        %{query | ref: ref}
    end
  end

  @doc """
  Clears the entire prepared query cache.
  """
  @spec clear(cache()) :: :ok
  def clear(cache) do
    :ets.delete_all_objects(cache)
    :ok
  end

  @spec size(nil) :: integer()
  def size(nil), do: 0

  @spec size(cache()) :: integer()
  def size(cache) do
    :ets.info(cache) |> Keyword.get(:size, 0)
  end
end
