defmodule Tanks.MixProject do
  use Mix.Project

  def project do
    [
      app: :jam_19_tanks,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ranch],
      mod: {Tanks.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.7.0"},
      {:poison, "~> 3.1"},
      {:secure_random, "~> 0.5"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:distillery, "~> 2.0"}
    ]
  end
end
