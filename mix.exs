defmodule EctoSQLite3.MixProject do
  use Mix.Project

  @version "0.19.0"

  def project do
    [
      app: :ecto_sqlite3,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/elixir-sqlite/ecto_sqlite3",
      homepage_url: "https://github.com/elixir-sqlite/ecto_sqlite3",
      deps: deps(),
      package: package(),
      description: description(),
      test_paths: test_paths(System.get_env("EXQLITE_INTEGRATION")),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),

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
      {:ecto_sql, "~> 3.12"},
      {:ecto, "~> 3.12"},
      {:exqlite, "~> 0.22"},
      {:ex_doc, "~> 0.27", only: [:dev], runtime: false},
      {:jason, ">= 0.0.0", only: [:dev, :test, :docs]},
      {:temp, "~> 0.4", only: [:test]},
      {:credo, "~> 1.6", only: [:dev, :test, :docs]},

      # Benchmarks
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_markdown, "~> 0.2", only: :dev},
      {:postgrex, "~> 0.15", only: :dev},
      {:myxql, "~> 0.6", only: :dev}
    ]
  end

  defp description do
    "An SQLite3 Ecto3 adapter."
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
      main: "Ecto.Adapters.SQLite3",
      source_ref: "v#{@version}",
      source_url: "https://github.com/elixir-sqlite/ecto_sqlite3"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(nil), do: ["test"]
  defp test_paths(_any), do: ["integration_test"]

  defp aliases do
    [
      lint: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --all --strict"
      ]
    ]
  end
end
