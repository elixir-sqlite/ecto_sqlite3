defmodule EctoSQLite3.Schemas.Product do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoSQLite3.Schemas.Account

  schema "products" do
    field(:name, :string)
    field(:description, :string)
    field(:external_id, Ecto.UUID)
    field(:type, Ecto.Enum, values: [inventory: 1, non_inventory: 2])
    field(:bid, :binary_id)
    field(:tags, {:array, :string}, default: [])
    field(:approved_at, :naive_datetime)
    field(:ordered_at, :utc_datetime)
    field(:price, :decimal)

    belongs_to(:account, Account)

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :name,
      :description,
      :tags,
      :account_id,
      :approved_at,
      :ordered_at,
      :inserted_at,
      :type
    ])
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
