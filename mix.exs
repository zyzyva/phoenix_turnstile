defmodule PhoenixTurnstile.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/zyzyva/phoenix_turnstile"

  def project do
    [
      app: :phoenix_turnstile,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      test_coverage: [
        summary: [threshold: 75],
        ignore_modules: [
          Mix.Tasks.PhoenixTurnstile.Install
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # HTTP client for Turnstile verification
      {:req, "~> 0.5"},

      # Optional dependencies for Phoenix integration
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 0.20 or ~> 1.0", optional: true},

      # Igniter for intelligent code generation
      {:igniter, "~> 0.3"},

      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Cloudflare Turnstile integration for Phoenix applications with graceful failure handling.
    Includes automatic CSP configuration, Phoenix components, and LiveView hooks.
    """
  end

  defp package do
    [
      name: "phoenix_turnstile",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      maintainers: ["Zyzyva Team"],
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "PhoenixTurnstile",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
