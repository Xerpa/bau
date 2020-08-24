defmodule Bau.MixProject do
  use Mix.Project

  alias Elixir.Version

  def project do
    elixir_version = Version.parse!(System.version())

    [
      app: :bau,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(elixir_version)
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps(%Version{major: 1, minor: 6}) do
    [
      {:absinthe, ">= 1.4.0 and < 1.5.0"},
      {:conduit, ">= 0.8.0 and < 0.13.0"},
      {:ecto, ">= 2.2.0 and < 3.0.0"},
      {:poison, "~> 3.1"},
      {:tesla, ">= 1.0.0 and < 2.0.0"}
    ]
  end

  defp deps(%Version{}) do
    [
      {:absinthe, ">= 1.4.0 and < 1.5.0"},
      {:conduit, ">= 0.8.0 and < 0.13.0"},
      {:ecto, ">= 2.2.0 and < 4.0.0"},
      {:poison, "~> 3.1"},
      {:tesla, ">= 1.0.0 and < 2.0.0"}
    ]
  end
end
