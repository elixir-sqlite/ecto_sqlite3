defmodule Ecto.Integration.MathTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Schemas.Account
  alias EctoSQLite3.Schemas.Product
  alias EctoSQLite3.Schemas.Vec3f

  import Ecto.Query

  @moduletag :integration

  defp random_string(len) do
    :crypto.strong_rand_bytes(len)
    |> Base.url_encode64()
    |> binary_part(0, len)
  end

  defp create_account(name) do
    TestRepo.insert!(%Account{name: name})
  end

  defp create_product(account, price) do
    TestRepo.insert!(%Product{
      name: random_string(8),
      price: price,
      account_id: account.id
    })
  end

  describe "max" do
    test "decimal" do
      account = create_account("Company")
      create_product(account, Decimal.new("1.23"))
      create_product(account, Decimal.new("2.00"))
      create_product(account, Decimal.new("2.67"))

      query = from(p in Product, select: max(p.price))

      [highest_price] = TestRepo.all(query)
      assert Decimal.equal?(highest_price, Decimal.new("2.67"))
    end
  end

  describe "min" do
    test "decimal" do
      account = create_account("Company")
      create_product(account, Decimal.new("1.23"))
      create_product(account, Decimal.new("2.00"))
      create_product(account, Decimal.new("2.67"))

      query = from(p in Product, select: min(p.price))

      [lowest_price] = TestRepo.all(query)
      assert Decimal.equal?(lowest_price, Decimal.new("1.23"))
    end
  end

  describe "sum" do
    test "decimal" do
      account = create_account("Company")
      create_product(account, Decimal.new("1.23"))
      create_product(account, Decimal.new("2.00"))
      create_product(account, Decimal.new("2.67"))

      query = from(p in Product, select: sum(p.price))

      [total] = TestRepo.all(query)
      assert Decimal.equal?(total, Decimal.new("5.90"))
    end
  end

  describe "avg" do
    test "decimal" do
      account = create_account("Company")
      create_product(account, Decimal.new("1.23"))
      create_product(account, Decimal.new("2.00"))
      create_product(account, Decimal.new("2.67"))

      query = from(p in Product, select: avg(p.price))

      [average] = TestRepo.all(query)
      assert Decimal.equal?(average, Decimal.new("1.9666666666666668"))
    end
  end

  describe "acos" do
    test "decimal above 1.0" do
      account = create_account("Company")
      create_product(account, Decimal.new("1.23"))

      query = from(p in Product, select: fragment("acos(?)", p.price))

      assert [nil] = TestRepo.all(query)
    end

    test "decimal below -1.0" do
      account = create_account("Company")
      create_product(account, Decimal.new("-1.23"))

      query = from(p in Product, select: fragment("acos(?)", p.price))

      assert [nil] = TestRepo.all(query)
    end

    test "decimal at 0.3" do
      account = create_account("Company")
      create_product(account, Decimal.new("0.30"))

      query = from(p in Product, select: fragment("acos(?)", p.price))

      # Right now, sqlite will return the acos function as an IEEE float
      [num] = TestRepo.all(query)
      assert_in_delta num, 1.266103672779499, 0.000000000000001
    end

    test "float above 1.0" do
      TestRepo.insert!(%Vec3f{x: 1.1, y: 1.2, z: 1.3})

      query = from(v in Vec3f, select: fragment("acos(?)", v.x))

      assert [nil] = TestRepo.all(query)
    end

    test "float below -1.0" do
      TestRepo.insert!(%Vec3f{x: -1.1, y: 1.2, z: 1.3})

      query = from(v in Vec3f, select: fragment("acos(?)", v.x))

      assert [nil] = TestRepo.all(query)
    end

    test "float at 0.3" do
      TestRepo.insert!(%Vec3f{x: 0.3, y: 1.2, z: 1.3})

      query = from(v in Vec3f, select: fragment("acos(?)", v.x))

      [num] = TestRepo.all(query)

      assert_in_delta num, 1.266103672779499, 0.000000000000001
    end
  end
end
