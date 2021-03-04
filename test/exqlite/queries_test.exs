defmodule Exqlite.QueriesTest do
  use ExUnit.Case

  alias Exqlite.Queries
  alias Exqlite.Query

  describe ".put/2" do
    test "does not store an unnamed query" do
      cache = Queries.new()
      query = %Query{name: nil}

      {:ok, cache} = Queries.put(cache, query)

      assert Queries.size(cache) == 0
    end

    test "does not store an empty named query" do
      cache = Queries.new()
      query = %Query{name: "", ref: make_ref()}

      {:ok, cache} = Queries.put(cache, query)

      assert Queries.size(cache) == 0
    end

    test "does not store a named query with no ref" do
      cache = Queries.new()
      query = %Query{name: "", ref: nil}

      {:ok, cache} = Queries.put(cache, query)

      assert Queries.size(cache) == 0
    end

    test "stores a named query" do
      cache = Queries.new()
      query = %Query{name: "myquery", ref: make_ref()}

      {:ok, cache} = Queries.put(cache, query)

      assert Queries.size(cache) == 1
    end

    test "stores named query in only one cache" do
      cache1 = Queries.new()
      cache2 = Queries.new()
      query = %Query{name: "myquery", ref: make_ref()}

      {:ok, cache1} = Queries.put(cache1, query)

      assert Queries.size(cache1) == 1
      assert Queries.size(cache2) == 0
    end
  end

  describe ".get/2" do
    test "returns nil when query is unnamed" do
      cache = Queries.new()
      query = %Query{name: nil, ref: make_ref()}
      Queries.put(cache, query)

      {:ok, nil} = Queries.get(cache, query)
    end

    test "returns nil when query has a blank name" do
      cache = Queries.new()
      query = %Query{name: "", ref: make_ref()}
      Queries.put(cache, query)

      {:ok, nil} = Queries.get(cache, query)
    end

    test "returns the stored named query" do
      cache = Queries.new()
      existing = %Query{name: "myquery", ref: make_ref()}
      {:ok, cache} = Queries.put(cache, existing)

      {:ok, found} = Queries.get(cache, %Query{name: "myquery", ref: nil})

      assert found.ref == existing.ref
    end
  end

  describe ".delete/2" do
    test "returns error for unnamed query" do
      cache = Queries.new()
      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      {:ok, cache} = Queries.delete(cache, %Query{name: nil})

      assert Queries.size(cache) == 1
    end

    test "returns error for a blank named query" do
      cache = Queries.new()
      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      {:ok, cache} = Queries.delete(cache, %Query{name: ""})

      assert Queries.size(cache) == 1
    end

    test "deletes the named query" do
      cache = Queries.new()
      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      {:ok, cache} = Queries.delete(cache, %Query{name: "myquery"})

      assert Queries.size(cache) == 0
    end
  end

  describe ".clear/1" do
    test "clears an empty cache" do
      cache = Queries.new()

      {:ok, cache} = Queries.clear(cache)

      assert Queries.size(cache) == 0
    end

    test "clears a populated cache" do
      cache = Queries.new()
      existing = %Query{name: "myquery", ref: make_ref()}
      Queries.put(cache, existing)

      {:ok, _} = Queries.clear(cache)

      assert Queries.size(cache) == 0
    end
  end

  describe ".size/1" do
    test "returns 0 for an empty cache" do
      cache = Queries.new()
      assert Queries.size(cache) == 0
    end

    test "returns 1" do
      cache = Queries.new()
      existing = %Query{name: "myquery", ref: make_ref()}
      Queries.put(cache, existing)

      assert Queries.size(cache) == 1
    end
  end
end
