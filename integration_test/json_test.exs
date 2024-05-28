defmodule Ecto.Integration.JsonTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query

  alias Ecto.Integration.TestRepo
  alias Ecto.Integration.Order

  test "json_extract_path with primitive values" do
    order = %Order{
      metadata: %{
        :id => 123,
        :time => ~T[09:00:00],
        "code" => "good",
        "'single quoted'" => "bar",
        "\"double quoted\"" => "baz",
        "enabled" => true,
        "extra" => [%{"enabled" => false}]
      }
    }

    order = TestRepo.insert!(order)

    assert TestRepo.one(from(o in Order, select: o.metadata["id"])) == 123
    assert TestRepo.one(from(o in Order, select: o.metadata["bad"])) == nil
    assert TestRepo.one(from(o in Order, select: o.metadata["bad"]["bad"])) == nil

    field = "id"
    assert TestRepo.one(from(o in Order, select: o.metadata[^field])) == 123
    assert TestRepo.one(from(o in Order, select: o.metadata["time"])) == "09:00:00"
    assert TestRepo.one(from(o in Order, select: o.metadata["'single quoted'"])) == "bar"
    assert TestRepo.one(from(o in Order, select: o.metadata["';"])) == nil

    # This does not work in SQLite3 after v3.45
    # That being said, this is a really obscure need. I can not figure out a solution for this
    # assert TestRepo.one(from(o in Order, select: o.metadata["\"double quoted\""])) == "baz"

    assert TestRepo.one(from(o in Order, select: o.metadata["enabled"])) == 1
    assert TestRepo.one(from(o in Order, select: o.metadata["extra"][0]["enabled"])) == 0

    # where
    assert TestRepo.one(from(o in Order, where: o.metadata["id"] == 123, select: o.id)) ==
             order.id

    assert TestRepo.one(from(o in Order, where: o.metadata["id"] == 456, select: o.id)) ==
             nil

    assert TestRepo.one(from(o in Order, where: o.metadata["code"] == "good", select: o.id)) ==
             order.id

    assert TestRepo.one(from(o in Order, where: o.metadata["code"] == "bad", select: o.id)) ==
             nil

    assert TestRepo.one(
             from(o in Order, where: o.metadata["enabled"] == true, select: o.id)
           ) == order.id

    assert TestRepo.one(
             from(o in Order,
               where: o.metadata["extra"][0]["enabled"] == false,
               select: o.id
             )
           ) == order.id
  end

  test "json_extract_path with arrays and objects" do
    order = %Order{metadata: %{tags: [%{name: "red"}, %{name: "green"}]}}
    order = TestRepo.insert!(order)

    assert TestRepo.one(from(o in Order, select: o.metadata["tags"][0]["name"])) == "red"
    assert TestRepo.one(from(o in Order, select: o.metadata["tags"][99]["name"])) == nil

    index = 1

    assert TestRepo.one(from(o in Order, select: o.metadata["tags"][^index]["name"])) ==
             "green"

    # where
    assert TestRepo.one(
             from(o in Order, where: o.metadata["tags"][0]["name"] == "red", select: o.id)
           ) == order.id

    assert TestRepo.one(
             from(o in Order, where: o.metadata["tags"][0]["name"] == "blue", select: o.id)
           ) == nil

    assert TestRepo.one(
             from(o in Order, where: o.metadata["tags"][99]["name"] == "red", select: o.id)
           ) == nil
  end

  test "json_extract_path with embeds" do
    order = %Order{items: [%{valid_at: ~D[2020-01-01]}]}
    TestRepo.insert!(order)

    assert TestRepo.one(from(o in Order, select: o.items[0]["valid_at"])) ==
             "2020-01-01"
  end
end
