defmodule Emit.MixProject do
  use Mix.Project

  @repo_url "https://github.com/queer/emit"

  def project do
    [
      app: :emit,
      version: "0.1.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description: " Powerful metadata-backed pubsub for Elixir.",
      package: [
        maintainers: ["amy"],
        links: %{"GitHub" => @repo_url},
        licenses: ["MIT"]
      ],

      # Docs
      name: "Emit",
      docs: [
        homepage_url: @repo_url,
        source_url: @repo_url,
        extras: [
          "README.md"
        ]
      ]
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "bench.1k": "run bench/benchmark_1k.exs",
      "bench.10k": "run bench/benchmark_10k.exs",
      "bench.100k": "run bench/benchmark_100k.exs"
    ]
  end
end
