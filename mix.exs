defmodule Bau.MixProject do
  use Mix.Project

  def project do
    [
      app: :bau,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 3.1"}, {:jose, "~> 1.8.4"}]
  end
end
