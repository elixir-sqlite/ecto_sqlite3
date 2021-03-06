defmodule Exqlite.Result do
  @type t :: %__MODULE__{
          command: atom,
          columns: [String.t()] | nil,
          rows: [[term] | term] | nil,
          num_rows: integer(),
          last_insert_id: any()
        }

  defstruct command: nil, columns: [], rows: [], num_rows: 0, last_insert_id: nil

  def new(options) do
    %__MODULE__{
      command: Keyword.get(options, :command),
      columns: Keyword.get(options, :columns, []),
      rows: Keyword.get(options, :rows, []),
      num_rows: Keyword.get(options, :num_rows, 0),
      last_insert_id: Keyword.get(options, :last_insert_id)
    }
  end
end
