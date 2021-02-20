defmodule Exqlite.Result do
  @type t :: %__MODULE__{
          command: atom,
          columns: [String.t()] | nil,
          rows: [[term] | term] | nil,
          num_rows: integer
        }

  defstruct command: nil, columns: [], rows: [], num_rows: 0
end
