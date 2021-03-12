defmodule Ecto.Integration.CrudTest do
  use Ecto.Integration.Case

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
          approved_at: nil
        }
        |> TestRepo.insert()

      found = TestRepo.get(Product, product.id)
      assert found.id == product.id
      assert found.approved_at == nil
      assert found.description == nil
      assert found.name == "Thing"
      assert found.tags == []
    end

    test "insert_all" do
      timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      account = %{
        name: "John",
        inserted_at: timestamp,
        updated_at: timestamp,
      }
      {1, nil} = TestRepo.insert_all(Account, [account], [])
    end

  end

  describe "delete" do
    test "deletes user" do
      {:ok, user} = TestRepo.insert(%User{name: "John"}, [])

      {:ok, _} = TestRepo.delete(user)
    end

    @tag :busy_repo
    test "delete_all deletes one product" do
      TestRepo.insert!(%Product{name: "hello"})

      # we have to do this because the tests are not isolated from one another.
      # @kevinlang is working on rectifying that problem
      assert {total, _} = TestRepo.delete_all(Product)
      assert total >= 1
    end

    # this test keeps on hitting busy issues, not sure why
    # one error i saw, tho not sure what test exactly, was
    # passes fine in isolation.
    @tag :busy_repo
    test "delete_all deletes all products" do
      TestRepo.insert!(%Product{name: "hello"})
      TestRepo.insert!(%Product{name: "hello again"})

      # we have to do this because the tests are not isolated from one another.
      # @kevinlang is working on rectifying that problem
      assert {total, _} = TestRepo.delete_all(Product)
      assert total >= 2
    end
  end

  describe "update" do
    test "updates user" do
      {:ok, user} = TestRepo.insert(%User{name: "John"}, [])
      changeset = User.changeset(user, %{name: "Bob"})

      {:ok, changed} = TestRepo.update(changeset)

      assert changed.name == "Bob"
    end

    test "update_all handles null<->nil conversion correctly" do
      account = TestRepo.insert!(%Account{name: "hello"})
      assert {1, nil} = TestRepo.update_all(Account, set: [name: nil])
      assert %Account{name: nil} = TestRepo.reload(account)
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

  describe "preloading" do
    test "preloads many to many relation" do
      account1 = TestRepo.insert!(%Account{name: "Main"})
      account2 = TestRepo.insert!(%Account{name: "Secondary"})
      user1 = TestRepo.insert!(%User{name: "John"}, [])
      user2 = TestRepo.insert!(%User{name: "Shelly"}, [])
      TestRepo.insert!(%AccountUser{user_id: user1.id, account_id: account1.id})
      TestRepo.insert!(%AccountUser{user_id: user1.id, account_id: account2.id})
      TestRepo.insert!(%AccountUser{user_id: user2.id, account_id: account2.id})

      accounts = from(a in Account, preload: [:users]) |> TestRepo.all()

      assert Enum.count(accounts) == 2
      Enum.each(accounts, fn account ->
        assert Ecto.assoc_loaded?(account.users)
      end)
    end
  end

  describe "select" do
    test "can handle in" do
      TestRepo.insert!(%Account{name: "hi"})
      assert [] = TestRepo.all from a in Account, where: a.name in ["404"]
      assert [_] = TestRepo.all from a in Account, where: a.name in ["hi"]
    end
  end
end
