defmodule LoggerPapertrailBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :logger_papertrail_backend,
     version: "0.1.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [],
    mod: { LoggerPapertrailBackend, []}]
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
    []
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
                "Logger" => "http://elixir-lang.org/docs/stable/logger/Logger.html",
                "Papertrail" => "https://papertrailapp.com/"}
    ]
  end
end
