defmodule Ecto.Integration.BlobTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo
  alias EctoSQLite3.Schemas.Setting

  @moduletag :integration

  test "updates blob to nil" do
    setting =
      %Setting{}
      |> Setting.changeset(%{checksum: <<0x00, 0x01>>})
      |> TestRepo.insert!()

    # Read the record back using ecto and confirm it
    assert %Setting{checksum: <<0x00, 0x01>>} =
             TestRepo.get(Setting, setting.id)

    assert %Setting{checksum: nil} =
             setting
             |> Setting.changeset(%{checksum: nil})
             |> TestRepo.update!()
  end
end
