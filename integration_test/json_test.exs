defmodule Ecto.Integration.JsonTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query

  alias Ecto.Integration.TestRepo
  alias Ecto.Integration.Order

  test "json_extract_path with primitive values" do
    order = %Order{
      meta: %{
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

    assert TestRepo.one(from(o in Order, select: o.meta["id"])) == 123
    assert TestRepo.one(from(o in Order, select: o.meta["bad"])) == nil
    assert TestRepo.one(from(o in Order, select: o.meta["bad"]["bad"])) == nil

    field = "id"
    assert TestRepo.one(from(o in Order, select: o.meta[^field])) == 123
    assert TestRepo.one(from(o in Order, select: o.meta["time"])) == "09:00:00"
    assert TestRepo.one(from(o in Order, select: o.meta["'single quoted'"])) == "bar"
    assert TestRepo.one(from(o in Order, select: o.meta["';"])) == nil
    assert TestRepo.one(from(o in Order, select: o.meta["\"double quoted\""])) == "baz"
    assert TestRepo.one(from(o in Order, select: o.meta["enabled"])) == 1
    assert TestRepo.one(from(o in Order, select: o.meta["extra"][0]["enabled"])) == 0

    # where
    assert TestRepo.one(from(o in Order, where: o.meta["id"] == 123, select: o.id)) ==
             order.id

    assert TestRepo.one(from(o in Order, where: o.meta["id"] == 456, select: o.id)) ==
             nil

    assert TestRepo.one(from(o in Order, where: o.meta["code"] == "good", select: o.id)) ==
             order.id

    assert TestRepo.one(from(o in Order, where: o.meta["code"] == "bad", select: o.id)) ==
             nil

    assert TestRepo.one(
             from(o in Order, where: o.meta["enabled"] == true, select: o.id)
           ) == order.id

    assert TestRepo.one(
             from(o in Order,
               where: o.meta["extra"][0]["enabled"] == false,
               select: o.id
             )
           ) == order.id
  end

  test "json_extract_path with arrays and objects" do
    order = %Order{meta: %{tags: [%{name: "red"}, %{name: "green"}]}}
    order = TestRepo.insert!(order)

    assert TestRepo.one(from(o in Order, select: o.meta["tags"][0]["name"])) == "red"
    assert TestRepo.one(from(o in Order, select: o.meta["tags"][99]["name"])) == nil

    index = 1

    assert TestRepo.one(from(o in Order, select: o.meta["tags"][^index]["name"])) ==
             "green"

    # where
    assert TestRepo.one(
             from(o in Order, where: o.meta["tags"][0]["name"] == "red", select: o.id)
           ) == order.id

    assert TestRepo.one(
             from(o in Order, where: o.meta["tags"][0]["name"] == "blue", select: o.id)
           ) == nil

    assert TestRepo.one(
             from(o in Order, where: o.meta["tags"][99]["name"] == "red", select: o.id)
           ) == nil
  end

  test "json_extract_path with embeds" do
    order = %Order{items: [%{valid_at: ~D[2020-01-01]}]}
    TestRepo.insert!(order)

    assert TestRepo.one(from(o in Order, select: o.items[0]["valid_at"])) ==
             "2020-01-01"
  end
end
