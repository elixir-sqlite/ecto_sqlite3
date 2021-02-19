defmodule Exqlite.Result do
  @type t :: %__MODULE__{
          command: atom,
          columns: [String.t()] | nil,
          rows: [[term] | term] | nil,
          num_rows: integer
        }

  defstruct command: nil, columns: nil, rows: nil, num_rows: nil
end
