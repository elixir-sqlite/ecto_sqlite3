defmodule Exqlite.QueriesTest do
  use ExUnit.Case

  alias Exqlite.Queries
  alias Exqlite.Query

  describe ".put/2" do
    test "does not store an unnamed query" do
      cache = Queries.new(:foo)
      query = %Query{name: nil}

      assert :error == Queries.put(cache, query)
      assert 0 == Queries.size(cache)
    end

    test "does not store an empty named query" do
      cache = Queries.new(:foo)
      query = %Query{name: "", ref: make_ref()}

      assert :error == Queries.put(cache, query)
      assert 0 == Queries.size(cache)
    end

    test "does not store a named query with no ref" do
      cache = Queries.new(:foo)
      query = %Query{name: "", ref: nil}

      assert :error == Queries.put(cache, query)
      assert 0 == Queries.size(cache)
    end

    test "stores a named query" do
      cache = Queries.new(:foo)
      query = %Query{name: "myquery", ref: make_ref()}

      assert :ok == Queries.put(cache, query)
      assert 1 == Queries.size(cache)
    end

    test "stores named query in only one cache" do
      cache1 = Queries.new(:foo)
      cache2 = Queries.new(:foo)
      query = %Query{name: "myquery", ref: make_ref()}

      assert :ok == Queries.put(cache1, query)

      assert 1 == Queries.size(cache1)
      assert 0 == Queries.size(cache2)
    end
  end

  describe ".get/2" do
    test "returns nil when query is unnamed" do
      cache = Queries.new(:foo)
      query = %Query{name: nil, ref: make_ref()}
      Queries.put(cache, query)

      refute Queries.get(cache, query)
    end

    test "returns nil when query has a blank name" do
      cache = Queries.new(:foo)
      query = %Query{name: "", ref: make_ref()}
      Queries.put(cache, query)

      refute Queries.get(cache, query)
    end

    test "returns the stored named query" do
      cache = Queries.new(:foo)
      existing = %Query{name: "myquery", ref: make_ref()}
      Queries.put(cache, existing)

      found = Queries.get(cache, %Query{name: "myquery", ref: nil})

      assert found.ref == existing.ref
    end
  end

  describe ".delete/2" do
    test "returns error for unnamed query" do
      cache = Queries.new(:foo)

      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      assert :error == Queries.delete(cache, %Query{name: nil})
      assert 1 == Queries.size(cache)
    end

    test "returns error for a blank named query" do
      cache = Queries.new(:foo)

      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      assert :error == Queries.delete(cache, %Query{name: ""})
      assert 1 == Queries.size(cache)
    end

    test "deletes the named query" do
      cache = Queries.new(:foo)

      Queries.put(cache, %Query{name: "myquery", ref: make_ref()})

      assert :ok == Queries.delete(cache, %Query{name: "myquery"})
      assert 0 == Queries.size(cache)
    end
  end

  describe ".clear/1" do
    test "clears an empty cache" do
      cache = Queries.new(:foo)
      assert :ok == Queries.clear(cache)
    end

    test "clears a populated cache" do
      cache = Queries.new(:foo)
      existing = %Query{name: "myquery", ref: make_ref()}
      Queries.put(cache, existing)

      assert :ok == Queries.clear(cache)
    end
  end

  describe ".size/1" do
    test "returns 0 for a nil" do
      assert Queries.size(nil) == 0
    end

    test "returns 0 for an empty cache" do
      cache = Queries.new(:foo)
      assert Queries.size(cache) == 0
    end

    test "returns 1" do
      cache = Queries.new(:foo)
      existing = %Query{name: "myquery", ref: make_ref()}
      Queries.put(cache, existing)

      assert Queries.size(cache) == 1
    end
  end
end
