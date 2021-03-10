defmodule Exqlite.Pragma do
  @moduledoc """
  Handles parsing extra options for the SQLite connection
  """

  def busy_timeout(nil), do: busy_timeout([])

  def busy_timeout(options) do
    Keyword.get(options, :busy_timeout, 2000)
  end

  def journal_mode(nil), do: journal_mode([])

  def journal_mode(options) do
    case Keyword.get(options, :journal_mode, :delete) do
      :delete -> "DELETE"
      :memory -> "MEMORY"
      :off -> "OFF"
      :persist -> "PERSIST"
      :truncate -> "TRUNCATE"
      :wal -> "WAL"
      _ -> raise ArgumentError, "invalid :journal_mode"
    end
  end

  def temp_store(nil), do: temp_store([])

  def temp_store(options) do
    case Keyword.get(options, :temp_store, :default) do
      :file -> 1
      :memory -> 2
      :default -> 0
      _ -> raise ArgumentError, "invalid :temp_store"
    end
  end

  def synchronous(nil), do: synchronous([])

  def synchronous(options) do
    case Keyword.get(options, :synchronous, :normal) do
      :extra -> 3
      :full -> 2
      :normal -> 1
      :off -> 0
      _ -> raise ArgumentError, "invalid :synchronous"
    end
  end

  def foreign_keys(nil), do: foreign_keys([])

  def foreign_keys(options) do
    case Keyword.get(options, :foreign_keys, :on) do
      :off -> 0
      :on -> 1
      _ -> raise ArgumentError, "invalid :foreign_keys"
    end
  end

  def cache_size(nil), do: cache_size([])

  def cache_size(options) do
    Keyword.get(options, :cache_size, -2000)
  end

  def cache_spill(nil), do: cache_spill([])

  def cache_spill(options) do
    case Keyword.get(options, :cache_spill, :on) do
      :off -> 0
      :on -> 1
      _ -> raise ArgumentError, "invalid :cache_spill"
    end
  end

  def case_sensitive_like(nil), do: case_sensitive_like([])

  def case_sensitive_like(options) do
    case Keyword.get(options, :case_sensitive_like, :off) do
      :off -> 0
      :on -> 1
      _ -> raise ArgumentError, "invalid :case_sensitive_like"
    end
  end

  def auto_vacuum(nil), do: auto_vacuum([])

  def auto_vacuum(options) do
    case Keyword.get(options, :auto_vacuum, :none) do
      :none -> 0
      :full -> 1
      :incremental -> 2
      _ -> raise ArgumentError, "invalid :auto_vacuum"
    end
  end

  def locking_mode(nil), do: locking_mode([])

  def locking_mode(options) do
    case Keyword.get(options, :locking_mode, :normal) do
      :normal -> "NORMAL"
      :exclusive -> "EXCLUSIVE"
      _ -> raise ArgumentError, "invalid :locking_mode"
    end
  end

  def secure_delete(nil), do: secure_delete([])

  def secure_delete(options) do
    case Keyword.get(options, :secure_delete, :off) do
      :off -> 0
      :on -> 1
      _ -> raise ArgumentError, "invalid :secure_delete"
    end
  end

  def wal_auto_check_point(nil), do: wal_auto_check_point([])

  def wal_auto_check_point(options) do
    Keyword.get(options, :wal_auto_check_point, 1000)
  end
end
