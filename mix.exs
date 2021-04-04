defmodule EctoSQLite3.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_sqlite3,
      version: "0.5.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/elixir-sqlite/ecto_sqlite3",
      homepage_url: "https://github.com/elixir-sqlite/ecto_sqlite3",
      deps: deps(),
      package: package(),
      description: description(),
      test_paths: test_paths(System.get_env("EXQLITE_INTEGRATION")),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "Ecto SQLite3",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:decimal, "~> 1.6 or ~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:ecto, "~> 3.5"},
      {:exqlite, "~> 0.5"},
      {:ex_doc, "~> 0.23.0", only: [:dev], runtime: false},
      {:jason, ">= 0.0.0", only: [:bench, :test, :docs]},
      {:temp, "~> 0.4", only: [:test]},

      # Benchmarks
      {:benchee, "~> 1.0", only: :bench},
      {:benchee_markdown, "~> 0.2", only: :bench},
      {:postgrex, "~> 0.15.0", only: :bench},
      {:myxql, "~> 0.4.0", only: :bench}
    ]
  end

  defp description do
    "A SQLite3 Ecto3 adapter."
  end

  defp package do
    [
      files: ~w(
        lib
        .formatter.exs
        mix.exs
        README.md
        LICENSE
      ),
      name: "ecto_sqlite3",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-sqlite/ecto_sqlite3",
        "docs" => "https://hexdocs.pm/ecto_sqlite3"
      }
    ]
  end

  defp docs do
    [
      main: "Ecto.Adapters.SQLite3"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(nil), do: ["test"]
  defp test_paths(_any), do: ["integration_test"]
end
