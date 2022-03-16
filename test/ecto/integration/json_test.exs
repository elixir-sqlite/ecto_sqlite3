defmodule Ecto.Integration.JsonTest do
  use Ecto.Integration.Case

  alias EctoSQLite3.Integration.Setting
  alias Ecto.Integration.TestRepo

  test "serializes json correctly" do
    # Insert a record purposefully with atoms as the map key. We are going to
    # verify later they were coerced into strings.
    setting =
      %Setting{}
      |> Setting.changeset(%{properties: %{foo: "bar", qux: "baz"}})
      |> TestRepo.insert!()

    # Read the record back using ecto and confirm it
    assert %Setting{properties: %{"foo" => "bar", "qux" => "baz"}} =
             TestRepo.get(Setting, setting.id)

    assert %{num_rows: 1, rows: [["bar"]]} =
             Ecto.Adapters.SQL.query!(
               TestRepo,
               "select json_extract(properties, '$.foo') from settings where id = ?1",
               [setting.id]
             )
  end
end
