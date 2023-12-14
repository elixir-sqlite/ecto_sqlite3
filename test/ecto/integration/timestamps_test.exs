defmodule Ecto.Integration.TimestampsTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Schemas.Account
  alias EctoSQLite3.Schemas.Product

  import Ecto.Query

  defmodule UserNaiveDatetime do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:name, :string)
      timestamps()
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:name])
      |> validate_required([:name])
    end
  end

  defmodule UserUtcDatetime do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:name, :string)
      timestamps(type: :utc_datetime)
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:name])
      |> validate_required([:name])
    end
  end

  setup do
    on_exit(fn -> Application.delete_env(:ecto_sqlite3, :datetime_type) end)
  end

  test "insert and fetch naive datetime" do
    # iso8601 type
    {:ok, user} =
      %UserNaiveDatetime{}
      |> UserNaiveDatetime.changeset(%{name: "Bob"})
      |> TestRepo.insert()

    user =
      UserNaiveDatetime
      |> select([u], u)
      |> where([u], u.id == ^user.id)
      |> TestRepo.one()

    assert user

    # text_datetime type
    Application.put_env(:ecto_sqlite3, :datetime_type, :text_datetime)

    {:ok, user} =
      %UserNaiveDatetime{}
      |> UserNaiveDatetime.changeset(%{name: "Bob"})
      |> TestRepo.insert()

    user =
      UserNaiveDatetime
      |> select([u], u)
      |> where([u], u.id == ^user.id)
      |> TestRepo.one()

    assert user
  end

  test "max of naive datetime" do
    # iso8601 type
    datetime = ~N[2014-01-16 20:26:51]
    TestRepo.insert!(%UserNaiveDatetime{inserted_at: datetime})
    query = from(p in UserNaiveDatetime, select: max(p.inserted_at))
    assert [^datetime] = TestRepo.all(query)

    # text_datetime type
    Application.put_env(:ecto_sqlite3, :datetime_type, :text_datetime)

    datetime = ~N[2014-01-16 20:26:51]
    TestRepo.insert!(%UserNaiveDatetime{inserted_at: datetime})
    query = from(p in UserNaiveDatetime, select: max(p.inserted_at))
    assert [^datetime] = TestRepo.all(query)
  end

  test "insert and fetch utc datetime" do
    # iso8601 type
    {:ok, user} =
      %UserUtcDatetime{}
      |> UserUtcDatetime.changeset(%{name: "Bob"})
      |> TestRepo.insert()

    user =
      UserUtcDatetime
      |> select([u], u)
      |> where([u], u.id == ^user.id)
      |> TestRepo.one()

    assert user

    # text_datetime type
    Application.put_env(:ecto_sqlite3, :datetime_type, :text_datetime)

    {:ok, user} =
      %UserUtcDatetime{}
      |> UserUtcDatetime.changeset(%{name: "Bob"})
      |> TestRepo.insert()

    user =
      UserUtcDatetime
      |> select([u], u)
      |> where([u], u.id == ^user.id)
      |> TestRepo.one()

    assert user
  end

  test "insert and fetch nil values" do
    now = DateTime.utc_now()

    {:ok, product} =
      %Product{}
      |> Product.changeset(%{name: "Nil Date Test", approved_at: now, ordered_at: now})
      |> TestRepo.insert()

    product = TestRepo.get(Product, product.id)
    assert product.name == "Nil Date Test"
    assert product.approved_at != now
    assert product.ordered_at != now
    assert product.approved_at == DateTime.truncate(now, :second) |> DateTime.to_naive()
    assert product.ordered_at == DateTime.truncate(now, :second)

    changeset = Product.changeset(product, %{approved_at: nil, ordered_at: nil})
    TestRepo.update(changeset)
    product = TestRepo.get(Product, product.id)
    assert product.approved_at == nil
    assert product.ordered_at == nil
  end

  test "datetime comparisons" do
    account =
      %Account{}
      |> Account.changeset(%{name: "Test"})
      |> TestRepo.insert!()

    %Product{}
    |> Product.changeset(%{
      account_id: account.id,
      name: "Foo",
      approved_at: ~U[2023-01-01T01:00:00Z]
    })
    |> TestRepo.insert!()

    %Product{}
    |> Product.changeset(%{
      account_id: account.id,
      name: "Bar",
      approved_at: ~U[2023-01-01T02:00:00Z]
    })
    |> TestRepo.insert!()

    %Product{}
    |> Product.changeset(%{
      account_id: account.id,
      name: "Qux",
      approved_at: ~U[2023-01-01T03:00:00Z]
    })
    |> TestRepo.insert!()

    since = ~U[2023-01-01T01:59:00Z]

    assert [
             %{name: "Qux"},
             %{name: "Bar"}
           ] =
             Product
             |> select([p], p)
             |> where([p], p.approved_at >= ^since)
             |> order_by([p], desc: p.approved_at)
             |> TestRepo.all()
  end
end
