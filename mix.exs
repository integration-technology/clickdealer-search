defmodule ClickdealerSearch.MixProject do
  use Mix.Project

  def project do
    [
      app: :clickdealer_search,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ClickdealerSearch.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.3"},
      {:jason, "~> 1.4"}
    ]
  end

  defp releases do
    [
      clickdealer_search: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end
end
