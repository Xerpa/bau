defmodule Bau.MixProject do
  use Mix.Project

  alias Elixir.Version

  def project do
    elixir_version = Version.parse!(System.version())

    [
      app: :bau,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(elixir_version),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/bau/test_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps(%Version{major: 1, minor: 6}) do
    [
      {:absinthe, ">= 1.4.0 and < 2.0.0", optional: true},
      {:conduit, ">= 0.8.0 and < 0.13.0", optional: true},
      {:ecto, ">= 2.2.0 and < 3.0.0", optional: true},
      {:poison, "~> 3.1", optional: true},
      {:tesla, ">= 1.0.0 and < 2.0.0", optional: true}
    ]
  end

  defp deps(%Version{}) do
    [
      {:absinthe, ">= 1.4.0 and < 2.0.0", optional: true},
      {:conduit, ">= 0.8.0 and < 0.13.0", optional: true},
      {:ecto, ">= 2.2.0 and < 4.0.0", optional: true},
      {:poison, "~> 3.1", optional: true},
      {:tesla, ">= 1.0.0 and < 2.0.0", optional: true},
      {:joken, "~> 2.3.0", optional: true},
      {:joken_jwks, "~> 1.4.1", optional: true}
    ]
  end
end
