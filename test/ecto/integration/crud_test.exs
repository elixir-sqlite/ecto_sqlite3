defmodule Ecto.Integration.CrudTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Integration.Account
  alias EctoSQLite3.Integration.AccountUser
  alias EctoSQLite3.Integration.Product
  alias EctoSQLite3.Integration.User

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
        updated_at: timestamp
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

    test "update_all returns correct rows format" do
      # update with no return value should have nil rows
      assert {0, nil} = TestRepo.update_all(User, set: [name: "WOW"])

      {:ok, _lj} = TestRepo.insert(%User{name: "Lebron James"}, [])

      # update with returning that updates nothing should return [] rows
      no_match_query =
        from(
          u in User,
          where: u.name == "Michael Jordan",
          select: %{name: u.name}
        )

      assert {0, []} = TestRepo.update_all(no_match_query, set: [name: "G.O.A.T"])

      # update with returning that updates something should return resulting RETURNING clause correctly
      match_query =
        from(
          u in User,
          where: u.name == "Lebron James",
          select: %{name: u.name}
        )

      assert {1, [%{name: "G.O.A.T"}]} =
               TestRepo.update_all(match_query, set: [name: "G.O.A.T"])
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
      assert [] = TestRepo.all(from(a in Account, where: a.name in ["404"]))
      assert [_] = TestRepo.all(from(a in Account, where: a.name in ["hi"]))
    end

    test "handles case sensitive text" do
      TestRepo.insert!(%Account{name: "hi"})
      assert [_] = TestRepo.all(from(a in Account, where: a.name == "hi"))
      assert [] = TestRepo.all(from(a in Account, where: a.name == "HI"))
    end

    test "handles case insensitive text" do
      TestRepo.insert!(%Account{name: "hi", email: "hi@hi.com"})
      assert [_] = TestRepo.all(from(a in Account, where: a.email == "hi@hi.com"))
      assert [_] = TestRepo.all(from(a in Account, where: a.email == "HI@HI.COM"))
    end

    test "handles exists subquery" do
      account1 = TestRepo.insert!(%Account{name: "Main"})
      user1 = TestRepo.insert!(%User{name: "John"}, [])
      TestRepo.insert!(%AccountUser{user_id: user1.id, account_id: account1.id})

      subquery =
        from(au in AccountUser, where: au.user_id == parent_as(:user).id, select: 1)

      assert [_] = TestRepo.all(from(a in Account, as: :user, where: exists(subquery)))
    end

    test "can handle fragment literal" do 
      account1 = TestRepo.insert!(%Account{name: "Main"})

      name = "name"
      query =
        from(a in Account, where: fragment("? = ?", literal(^name), "Main"))

      assert [account] = TestRepo.all(query)
      assert account.id == account1.id
    end

    test "can handle selected_as" do
      TestRepo.insert!(%Account{name: "Main"})
      TestRepo.insert!(%Account{name: "Main"})
      TestRepo.insert!(%Account{name: "Main2"})
      TestRepo.insert!(%Account{name: "Main3"})

      query =
        from(a in Account, 
          select: %{
            name: selected_as(a.name, :name2),
            count: count()
          },
          group_by: selected_as(:name2)
        )

      assert [%{name: "Main", count: 2}, %{name: "Main2", count: 1}, %{name: "Main3", count: 1}] = TestRepo.all(query)
    end

    test "can handle floats" do
      TestRepo.insert!(%Account{name: "Main"})

      one = "1.0"
      two = 2.0

      query =
        from(a in Account, 
          select: %{
            sum: ^one + ^two
          }
        )

      assert [%{sum: 3.0}] = TestRepo.all(query)
    end
  end
end
