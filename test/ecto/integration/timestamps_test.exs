defmodule Ecto.Integration.TimestampsTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo

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
end
