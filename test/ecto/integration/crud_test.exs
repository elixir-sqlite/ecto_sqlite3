defmodule Ecto.Integration.CrudTest do
  use ExUnit.Case

  alias Ecto.Integration.TestRepo
  alias Ecto.Integration.User

  test "create user" do
    {:ok, user1} = TestRepo.insert(%User{name: "John"}, [])
    assert user1

    {:ok, user2} = TestRepo.insert(%User{name: "James"}, [])
    assert user2

    assert user1.id != user2.id
  end
end
