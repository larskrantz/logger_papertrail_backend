defmodule LoggerPapertrailBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_papertrail_backend,
      version: "1.1.0",
      elixir: "~> 1.18",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger],
      mod: {LoggerPapertrailBackend, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.36", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
      A Papertrail backend for Elixir Logger
    """
  end

  defp package do
    [
      maintainers: ["Lars Krantz"],
      licenses: ["MIT"],
      links: %{ "GitHub" => "https://github.com/larskrantz/logger_papertrail_backend",
                "Logger" => "https://hexdocs.pm/logger/Logger.html",
                "Papertrail" => "https://papertrailapp.com/"}
    ]
  end
end
