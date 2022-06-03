defmodule AMI.MixProject do
  use Mix.Project

  def project do
    [
      app: :amiex,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],

      # Docs
      name: "AMI",
      source_url: "https://github.com/staskobzar/amiex",
      homepage_url: "https://github.com/staskobzar/amiex",
      docs: [
        main: "AMI",
        extras: ["README.md"]
      ]
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
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Elixir Asterisk Manager Interface library for AMI ver2."
  end

  defp package() do
    [
      licenses: ["GPL-3.0+"],
      links: %{"GitHub" => "https://github.com/staskobzar/amiex"}
    ]
  end
end
