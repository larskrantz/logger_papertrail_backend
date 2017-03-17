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
  Configures target using `syslog://` or `papertrail://` - scheme as url, or
  or configures target by extracting system-name, host and port from a keywordlist
  in the form of `[host: "hostname:port", system_name: "my_system_name"]`.
  `system_name` is optional.
  """
  @spec configure_papertrail_target([{:url, binary}]) :: %Configuration{ host: binary, port: integer, system_name: binary}
  def configure_papertrail_target([{:url, "syslog://" <> url} | _tail]), do: configure_papertrail_target([{:url,"papertrail://#{url}"}])
  @spec configure_papertrail_target([{:url, binary}]) :: %Configuration{ host: binary, port: integer, system_name: binary}
  def configure_papertrail_target([{:url, "papertrail://" <> url} | _tail]) do
    [host_and_port, system_name] = String.split(url, "/")
    [host, portstr] = String.split(host_and_port,":")
    port = String.to_integer(portstr)
    %Configuration{ host: host, port: port, system_name: system_name }
  end
  def configure_papertrail_target([{:url, faulty_url} | _tail]) when is_binary(faulty_url) do
    raise(LoggerPapertrailBackend.ConfigurationError, "Url in format '#{faulty_url}' is not supported as configuration. Please check docs.")
  end
  @spec configure_papertrail_target([{:host, binary}, {:system_name, binary}]) :: %Configuration{ host: binary, port: integer, system_name: binary}
  def configure_papertrail_target([{:host, host_config}, {:system_name, system_name}]) do
    [ host, portstr ] = host_config |> String.split(":")
    {port,_} = Integer.parse(portstr)
    %Configuration{ host: host, port: port, system_name: system_name }
  end
  @spec configure_papertrail_target([{:host, binary}]) :: %Configuration{ host: binary, port: integer, system_name: binary}
  def configure_papertrail_target([{:host, host_config}]), do: configure_papertrail_target(host: host_config, system_name: nil)
  def configure_papertrail_target(config) do
    raise(LoggerPapertrailBackend.ConfigurationError, "Unknown configuration: #{inspect(config)}")
  end
end
