defmodule Emit.MixProject do
  use Mix.Project

  def project do
    [
      app: :emit,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:lethe, "~> 0.6.0"},
      {:manifold, "~> 1.4"},

      {:benchee, "~> 1.1", only: [:dev, :test]},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
    ]
  end

  defp aliases do
    [
      "bench.1k": "run bench/benchmark_1k.exs",
      "bench.10k": "run bench/benchmark_10k.exs",
      "bench.100k": "run bench/benchmark_100k.exs",
    ]
  end
end
