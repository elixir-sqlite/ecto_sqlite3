defmodule EctoSQLite3.Integration.Account do
  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Integration.User
  alias EctoSQLite3.Integration.Product

  schema "accounts" do
    field(:name, :string)
    field(:email, :string)

    timestamps()

    many_to_many(:users, User, join_through: "account_users")
    has_many(:products, Product)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end

defmodule EctoSQLite3.Integration.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Integration.Account

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

defmodule EctoSQLite3.Integration.AccountUser do
  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Integration.Account
  alias EctoSQLite3.Integration.User

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

defmodule EctoSQLite3.Integration.Product do
  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Integration.Account

  schema "products" do
    field(:name, :string)
    field(:description, :string)
    field(:external_id, Ecto.UUID)
    field(:tags, {:array, :string}, default: [])
    field(:approved_at, :naive_datetime)
    field(:price, :decimal)

    belongs_to(:account, Account)

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :description, :tags])
    |> validate_required([:name])
    |> maybe_generate_external_id()
  end

  defp maybe_generate_external_id(changeset) do
    if get_field(changeset, :external_id) do
      changeset
    else
      put_change(changeset, :external_id, Ecto.UUID.bingenerate())
    end
  end
end

defmodule EctoSQLite3.Integration.Vec3f do
  use Ecto.Schema

  schema "vec3f" do
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
  end
end
