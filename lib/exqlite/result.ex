defmodule Exqlite.Result do
  @type t :: %__MODULE__{
          command: atom,
          columns: [String.t()] | nil,
          rows: [[term] | term] | nil
        }

  defstruct command: nil, columns: [], rows: []
end
