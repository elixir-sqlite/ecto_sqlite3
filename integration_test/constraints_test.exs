defmodule Ecto.Integration.ConstraintsTest do
  use ExUnit.Case, async: true

  import Ecto.Migrator, only: [up: 4]
  alias Ecto.Integration.PoolRepo

  defmodule ConstraintMigration do
    use Ecto.Migration

    @table table(:constraints_test)

    def change do
      create @table do
        add :price, :integer
        add :fromm, :integer
        add :too, :integer, check: %{name: "cannot_overlap", expr: "fromm < too"}
      end
    end
  end

  defmodule Constraint do
    use Ecto.Integration.Schema

    schema "constraints_test" do
      field :price, :integer
      field :fromm, :integer
      field :too, :integer
    end
  end

  @base_migration 2_000_000

  setup_all do
    ExUnit.CaptureLog.capture_log(fn ->
      num = @base_migration + System.unique_integer([:positive])
      up(PoolRepo, num, ConstraintMigration, log: false)
    end)

    :ok
  end

  @tag :create_constraint
  test "check constraint" do
    changeset = Ecto.Changeset.change(%Constraint{}, fromm: 0, too: 10)
    {:ok, _} = PoolRepo.insert(changeset)

    non_overlapping_changeset = Ecto.Changeset.change(%Constraint{}, fromm: 11, too: 12)
    {:ok, _} = PoolRepo.insert(non_overlapping_changeset)

    overlapping_changeset = Ecto.Changeset.change(%Constraint{}, fromm: 1900, too: 12)

    exception =
      assert_raise Ecto.ConstraintError, ~r/constraint error when attempting to insert struct/, fn ->
        PoolRepo.insert(overlapping_changeset)
      end
    assert exception.message =~ ~r/cannot_overlap.*\(check_constraint\)/
    assert exception.message =~ "The changeset has not defined any constraint."
    assert exception.message =~ "call `check_constraint/3`"

    {:error, changeset} =
      overlapping_changeset
      |> Ecto.Changeset.check_constraint(:fromm, name: :cannot_overlap)
      |> PoolRepo.insert()
    assert changeset.errors == [fromm: {"is invalid", [constraint: :check, constraint_name: "cannot_overlap"]}]
    assert changeset.data.__meta__.state == :built
  end
end
