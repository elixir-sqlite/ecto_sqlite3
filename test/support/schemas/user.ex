defmodule EctoSQLite3.Schemas.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Schemas.Account

  schema "users" do
    field(:name, :string)

    timestamps()

    many_to_many(:accounts, Account, join_through: "account_users")
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
