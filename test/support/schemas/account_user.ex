defmodule EctoSQLite3.Schemas.AccountUser do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Schemas.Account
  alias EctoSQLite3.Schemas.User

  schema "account_users" do
    timestamps()

    belongs_to(:account, Account)
    belongs_to(:user, User)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:account_id, :user_id])
    |> validate_required([:account_id, :user_id])
  end
end
