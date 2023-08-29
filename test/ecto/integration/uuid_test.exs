defmodule Ecto.Integration.UUIDTest do
  use Ecto.Integration.Case, async: false

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Schemas.Product

  import Ecto.Query, only: [from: 2]

  setup do
    Application.put_env(:ecto_sqlite3, :uuid_type, :string)
    on_exit(fn -> Application.put_env(:ecto_sqlite3, :uuid_type, :string) end)
  end

  test "handles uuid serialization and deserialization with string format " do
    external_id = Ecto.UUID.generate()
    product = TestRepo.insert!(%Product{name: "Pupper Beer", external_id: external_id})

    assert product.id
    assert product.external_id == external_id

    found = TestRepo.get(Product, product.id)
    assert found
    assert found.external_id == external_id
  end

  test "handles uuid serialization and deserialization with binary format " do
    Application.put_env(:ecto_sqlite3, :uuid_type, :binary)

    external_id = Ecto.UUID.generate()
    product = TestRepo.insert!(%Product{name: "Pupper Beer", external_id: external_id})

    assert product.id
    assert product.external_id == external_id

    found = TestRepo.get(Product, product.id)
    assert found
    assert found.external_id == external_id
  end

  test "handles uuid casting with binary format" do
    Application.put_env(:ecto_sqlite3, :uuid_type, :binary)
    Application.put_env(:ecto_sqlite3, :binary_id_type, :binary)

    external_id = Ecto.UUID.generate()
    TestRepo.insert!(%Product{external_id: external_id, bid: external_id})

    product = TestRepo.one(from(p in Product, where: p.external_id == type(p.bid, Ecto.UUID)))
    assert %{external_id: ^external_id} = product

    product = TestRepo.one(from(p in Product, where: p.external_id == type(^external_id, Ecto.UUID)))
    assert %{external_id: ^external_id} = product
  end

  test "handles binary_id casting with binary format" do
    Application.put_env(:ecto_sqlite3, :uuid_type, :binary)
    Application.put_env(:ecto_sqlite3, :binary_id_type, :binary)

    bid = Ecto.UUID.generate()
    TestRepo.insert!(%Product{bid: bid, external_id: bid})

    product = TestRepo.one(from(p in Product, where: p.bid == type(p.external_id, :binary_id)))
    assert %{bid: ^bid} = product

    product = TestRepo.one(from p in Product, where: p.bid == type(^bid, :binary_id))
    assert %{bid: ^bid} = product
  end
end
