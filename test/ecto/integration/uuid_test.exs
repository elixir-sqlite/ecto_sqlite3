defmodule Ecto.Integration.UUIDTest do
  use Ecto.Integration.Case, async: false

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Integration.Product

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
end
