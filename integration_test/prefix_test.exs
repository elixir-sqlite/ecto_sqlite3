defmodule Ecto.Integration.PrefixTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query, only: [from: 2]

  alias Ecto.Integration.Post
  alias Ecto.Integration.TestRepo

  test "queries an attached database through :prefix" do
    TestRepo.query!(~s|ATTACH DATABASE ":memory:" AS "foo"|)
    TestRepo.query!(~s|CREATE TABLE "foo"."posts" AS SELECT * FROM "main"."posts"|)

    TestRepo.insert!(%Post{id: 1}, prefix: "foo")

    results =
      from(Post, prefix: "foo")
      |> TestRepo.all()

    assert [%Post{id: 1}] = results
  end
end
