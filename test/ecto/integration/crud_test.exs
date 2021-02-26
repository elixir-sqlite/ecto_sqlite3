defmodule Ecto.Integration.CrudTest do
  use ExUnit.Case

  alias Ecto.Integration.TestRepo
  alias Exqlite.Integration.User

  test "create user" do
    {:ok, changeset} = TestRepo.insert(%User{name: "John"}, [])
    assert changeset
  end
end
