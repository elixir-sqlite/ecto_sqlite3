defmodule Ecto.Integration.RepoAltTest do
  use Ecto.Integration.Case, async: Application.get_env(:ecto, :async_integration_tests, true)

  alias Ecto.Integration.TestRepo
  import Ecto.Query

  alias Ecto.Integration.Post

  describe "insert_all with source query" do
    @tag :upsert
    @tag :with_conflict_target
    test "insert_all with query and conflict target" do
      {:ok, %Post{id: id}} = TestRepo.insert(%Post{
        title: "A generic title"
      })

      source = from p in Post,
        select: %{
          title: fragment("? || ? || ?", p.title, type(^" suffix ", :string), p.id)
        },
        where: true

      assert {1, _} = TestRepo.insert_all(Post, source, conflict_target: [:id], on_conflict: :replace_all)

      expected_id = id + 1
      expected_title = "A generic title suffix #{id}"

      assert %Post{title: ^expected_title} = TestRepo.get(Post, expected_id)
    end

    @tag :returning
    test "insert_all with query and returning" do
      {:ok, %Post{id: id}} = TestRepo.insert(%Post{
        title: "A generic title"
      })

      source = from p in Post,
        select: %{
          title: fragment("? || ? || ?", p.title, type(^" suffix ", :string), p.id)
        },
        where: true

      assert {1, returns} = TestRepo.insert_all(Post, source, returning: [:id, :title])

      expected_id = id + 1
      expected_title = "A generic title suffix #{id}"
      assert [%Post{id: ^expected_id, title: ^expected_title}] = returns
    end

    @tag :upsert
    @tag :without_conflict_target
    test "insert_all with query and on_conflict" do
      {:ok, %Post{id: id}} = TestRepo.insert(%Post{
        title: "A generic title"
      })

      source = from p in Post,
        select: %{
          title: fragment("? || ? || ?", p.title, type(^" suffix ", :string), p.id)
        },
        where: true

      assert {1, _} = TestRepo.insert_all(Post, source, on_conflict: :replace_all)

      expected_id = id + 1
      expected_title = "A generic title suffix #{id}"

      assert %Post{title: ^expected_title} = TestRepo.get(Post, expected_id)
    end

    test "insert_all with query" do
      {:ok, %Post{id: id}} = TestRepo.insert(%Post{
        title: "A generic title"
      })

      source = from p in Post,
        select: %{
          title: fragment("? || ? || ?", p.title, type(^" suffix ", :string), p.id)
        },
        where: true

      assert {1, _} = TestRepo.insert_all(Post, source)

      expected_id = id + 1
      expected_title = "A generic title suffix #{id}"

      assert %Post{title: ^expected_title} = TestRepo.get(Post, expected_id)
    end
  end
end
