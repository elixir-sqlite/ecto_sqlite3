defmodule Ecto.Integration.CrudTest do
  use ExUnit.Case

  alias Ecto.Integration.TestRepo
  alias Exqlite.Integration.Account
  alias Exqlite.Integration.User
  alias Exqlite.Integration.AccountUser
  alias Exqlite.Integration.Product

  import Ecto.Query

  describe "insert" do
    test "insert user" do
      {:ok, user1} = TestRepo.insert(%User{name: "John"}, [])
      assert user1

      {:ok, user2} = TestRepo.insert(%User{name: "James"}, [])
      assert user2

      assert user1.id != user2.id

      user =
        User
        |> select([u], u)
        |> where([u], u.id == ^user1.id)
        |> TestRepo.one()

      assert user.name == "John"
    end

    test "handles nulls when querying correctly" do
      {:ok, account} =
        %Account{name: "Something"}
        |> TestRepo.insert()
      {:ok, product} =
        %Product{
          name: "Thing",
          account_id: account.id,
          approved_at: nil,
        }
        |> TestRepo.insert()

      found = TestRepo.get(Product, product.id)
      assert found.id == product.id
      assert found.approved_at == nil
      assert found.description == nil
      assert found.name == "Thing"
      assert found.tags == []
    end
  end

  describe "transaction" do
    test "successful user and account creation" do
      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:account, fn _ ->
          Account.changeset(%Account{}, %{name: "Foo"})
        end)
        |> Ecto.Multi.insert(:user, fn _ ->
          User.changeset(%User{}, %{name: "Bob"})
        end)
        |> Ecto.Multi.insert(:account_user, fn %{account: account, user: user} ->
          AccountUser.changeset(%AccountUser{}, %{
            account_id: account.id,
            user_id: user.id
          })
        end)
        |> TestRepo.transaction()
    end

    test "unsuccessful account creation" do
      {:error, _, _, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:account, fn _ ->
          Account.changeset(%Account{}, %{name: nil})
        end)
        |> Ecto.Multi.insert(:user, fn _ ->
          User.changeset(%User{}, %{name: "Bob"})
        end)
        |> Ecto.Multi.insert(:account_user, fn %{account: account, user: user} ->
          AccountUser.changeset(%AccountUser{}, %{
            account_id: account.id,
            user_id: user.id
          })
        end)
        |> TestRepo.transaction()
    end

    test "unsuccessful user creation" do
      {:error, _, _, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:account, fn _ ->
          Account.changeset(%Account{}, %{name: "Foo"})
        end)
        |> Ecto.Multi.insert(:user, fn _ ->
          User.changeset(%User{}, %{name: nil})
        end)
        |> Ecto.Multi.insert(:account_user, fn %{account: account, user: user} ->
          AccountUser.changeset(%AccountUser{}, %{
            account_id: account.id,
            user_id: user.id
          })
        end)
        |> TestRepo.transaction()
    end
  end
end
