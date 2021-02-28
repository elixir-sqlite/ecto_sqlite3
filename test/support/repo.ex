defmodule Ecto.Integration.TestRepo do
  use Ecto.Repo, otp_app: :exqlite, adapter: Ecto.Adapters.Exqlite

  def create_prefix(prefix) do
    "create database #{prefix}"
  end

  def drop_prefix(prefix) do
    "drop database #{prefix}"
  end

  def uuid do
    Ecto.UUID
  end
end
