defmodule Exqlite.PragmaTest do
  use ExUnit.Case

  alias Exqlite.Pragma

  test ".journal_mode/1" do
    assert Pragma.journal_mode(journal_mode: :truncate) == "TRUNCATE"
    assert Pragma.journal_mode(journal_mode: :persist) == "PERSIST"
    assert Pragma.journal_mode(journal_mode: :memory) == "MEMORY"
    assert Pragma.journal_mode(journal_mode: :wal) == "WAL"
    assert Pragma.journal_mode(journal_mode: :off) == "OFF"
    assert Pragma.journal_mode(journal_mode: :delete) == "DELETE"
    assert Pragma.journal_mode([]) == "DELETE"
    assert Pragma.journal_mode(nil) == "DELETE"

    assert_raise(
      ArgumentError,
      "invalid :journal_mode",
      fn ->
        Pragma.journal_mode(journal_mode: :invalid)
      end
    )

    assert_raise(
      ArgumentError,
      "invalid :journal_mode",
      fn ->
        Pragma.journal_mode(journal_mode: "WAL")
      end
    )
  end

  test ".temp_store/1" do
    assert Pragma.temp_store(temp_store: :memory) == 2
    assert Pragma.temp_store(temp_store: :file) == 1
    assert Pragma.temp_store(temp_store: :default) == 0
    assert Pragma.temp_store([]) == 0
    assert Pragma.temp_store(nil) == 0

    assert_raise(
      ArgumentError,
      "invalid :temp_store",
      fn ->
        Pragma.temp_store(temp_store: :invalid)
      end
    )

    assert_raise(
      ArgumentError,
      fn ->
        Pragma.temp_store(temp_store: 1)
      end
    )
  end

  test ".synchronous/1" do
    assert Pragma.synchronous(synchronous: :extra) == 3
    assert Pragma.synchronous(synchronous: :full) == 2
    assert Pragma.synchronous(synchronous: :normal) == 1
    assert Pragma.synchronous(synchronous: :off) == 0
    assert Pragma.synchronous([]) == 1
    assert Pragma.synchronous(nil) == 1

    assert_raise(
      ArgumentError,
      "invalid :synchronous",
      fn ->
        Pragma.synchronous(synchronous: :invalid)
      end
    )
  end

  test ".foreign_keys/1" do
    assert Pragma.foreign_keys(foreign_keys: :on) == 1
    assert Pragma.foreign_keys(foreign_keys: :off) == 0
    assert Pragma.foreign_keys([]) == 1
    assert Pragma.foreign_keys(nil) == 1

    assert_raise(
      ArgumentError,
      "invalid :foreign_keys",
      fn ->
        Pragma.foreign_keys(foreign_keys: :invalid)
      end
    )
  end

  test ".cache_size/1" do
    assert Pragma.cache_size(cache_size: -64000) == -64000
    assert Pragma.cache_size([]) == -2000
    assert Pragma.cache_size(nil) == -2000
  end

  test ".cache_spill/1" do
    assert Pragma.cache_spill(cache_spill: :on) == 1
    assert Pragma.cache_spill(cache_spill: :off) == 0
    assert Pragma.cache_spill([]) == 1
    assert Pragma.cache_spill(nil) == 1

    assert_raise(
      ArgumentError,
      "invalid :cache_spill",
      fn ->
        Pragma.cache_spill(cache_spill: :invalid)
      end
    )
  end

  test ".case_sensitive_like/1" do
    assert Pragma.case_sensitive_like(case_sensitive_like: :on) == 1
    assert Pragma.case_sensitive_like(case_sensitive_like: :off) == 0
    assert Pragma.case_sensitive_like([]) == 0
    assert Pragma.case_sensitive_like(nil) == 0

    assert_raise(
      ArgumentError,
      "invalid :case_sensitive_like",
      fn ->
        Pragma.case_sensitive_like(case_sensitive_like: :invalid)
      end
    )
  end
end
