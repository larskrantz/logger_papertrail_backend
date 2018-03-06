defmodule LoggerPapertrailBackend.Configurator do
  alias LoggerPapertrailBackend.Configuration

  @moduledoc """
  You can config papertrail backend with an url in the form of papertrail://logs.papertrail.com:12345/my_system_name
  It works with syslog:// as scheme too.

  In your config, choose between
  ```elixir
  config :logger, :logger_papertrail_backend,
    url: "papertrail://logs.papertrail.com:12345/my_system_name"
  ```
  or
  ``` elixir
  config :logger, :logger_papertrail_backend,
    host: "logs.papertrailapp.com:12345",
    system_name: my_system_name
  ```
  ### Example

      iex> config = [url: "papertrail://logs.papertrail.com:12345/my_system_name"]
      iex> LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
      %LoggerPapertrailBackend.Configuration{host: "logs.papertrail.com", port: 12345, system_name: "my_system_name"}

      iex> host_config = [host: "logs.papertrail.com:12345", system_name: "my_system_name"]
      iex> LoggerPapertrailBackend.Configurator.configure_papertrail_target(host_config)
      %LoggerPapertrailBackend.Configuration{host: "logs.papertrail.com", port: 12345, system_name: "my_system_name"}
  """
  @doc """
  Configures target using a parsable URI as url, or
  or configures target by extracting system-name, host and port from a keywordlist
  in the form of `[host: "hostname:port", system_name: "my_system_name"]`.
  `system_name` is optional.
  """
  @spec configure_papertrail_target(configuration :: list) :: %Configuration{ host: binary, port: integer, system_name: binary}
  def configure_papertrail_target(configuration) when is_list(configuration) do
    configuration
    |> Enum.into(%{})
    |> configure_target
  end
  def configure_papertrail_target(configuration), do: configure_target(configuration)

  # private parts
  defp configure_target(%{url: url}), do: configure_target(URI.parse(url))
  defp configure_target(%URI{host: host, path: path, port: port}) do
    system_name = path |> clean_path
    %Configuration{ host: host, port: port, system_name: system_name }
  end
  defp configure_target(%{host: host_config, system_name: system_name}) do
    "papertrail://#{host_config}/#{system_name}"
    |> URI.parse
    |> configure_target
  end
  defp configure_target(%{host: host_config}), do: configure_target(%{host: host_config, system_name: nil})
  defp configure_target(config) do
    raise(LoggerPapertrailBackend.ConfigurationError, "Unknown configuration: #{inspect(config)}")
  end

  defp clean_path("/"), do: nil
  defp clean_path("/" <> rest), do: rest
  defp clean_path(_), do: nil
end
