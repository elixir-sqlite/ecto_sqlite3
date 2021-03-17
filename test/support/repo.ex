defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :ecto_sqlite3, adapter: Ecto.Adapters.SQLite3

  def create_prefix(_) do
    raise "SQLite3 does not support CREATE DATABASE"
  end

  def drop_prefix(_) do
    raise "SQLite3 does not support DROP DATABASE"
  end

  def uuid do
    Ecto.UUID
  end
end
