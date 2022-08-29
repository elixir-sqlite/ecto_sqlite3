defmodule Ecto.Integration.HintsTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query, only: [from: 2]

  alias Ecto.Integration.Post
  alias Ecto.Integration.TestRepo

  test "join hints" do
    {:ok, _} = TestRepo.query("CREATE INDEX post_id_idx ON posts (id)")
    TestRepo.insert!(%Post{id: 1})

    results =
      from(p in Post,
        join: p2 in Post,
        on: p.id == p2.id,
        hints: ["INDEXED BY post_id_idx"]
      )
      |> TestRepo.all()

    assert [%Post{id: 1}] = results
  end

  test "from hints" do
    {:ok, _} = TestRepo.query("CREATE INDEX post_id_idx ON posts (id)")
    TestRepo.insert!(%Post{id: 1})

    results =
      from(Post,
        hints: ["INDEXED BY post_id_idx"]
      )
      |> TestRepo.all()

    assert [%Post{id: 1}] = results
  end
end
