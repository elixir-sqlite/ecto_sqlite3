defmodule Exqlite.Result do
  @type t :: %__MODULE__{
          command: atom,
          columns: [String.t()] | nil,
          rows: [[term] | term] | nil,
          num_rows: integer(),
        }

  defstruct command: nil, columns: [], rows: [], num_rows: 0

  def new(options) do
    %__MODULE__{
      command: Keyword.get(options, :command),
      columns: Keyword.get(options, :columns, []),
      rows: Keyword.get(options, :rows, []),
      num_rows: Keyword.get(options, :num_rows, 0),
    }
  end
end
