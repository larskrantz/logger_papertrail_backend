defmodule LoggerPapertrailBackend.Configurator do
  alias LoggerPapertrailBackend.Configuration

  @moduledoc ~S"""
    You can config papertrail backend with an url in the form of papertrail://logs.papertrail.com:12345/my_system_name
    It works with syslog:// as scheme too.

    In your config, choose between
    config :logger, :logger_papertrail_backend,
      url: "papertrail://logs.papertrail.com:12345/my_system_name"

    or

    config :logger, :logger_papertrail_backend,
      host: "logs.papertrailapp.com:12345",
      system_name: my_system_name

    ## Example
      iex> config = [url: "papertrail://logs.papertrail.com:12345/my_system_name"]
      iex> LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
      %LoggerPapertrailBackend.Configuration{host: "logs.papertrail.com", port: 12345, system_name: "my_system_name"}
  """
  def configure_papertrail_target([{:url, "syslog://" <> url} | _tail]), do: configure_papertrail_target([{:url,"papertrail://#{url}"}])
  def configure_papertrail_target([{:url, "papertrail://" <> url} | _tail]) do
    [host_and_port, system_name] = String.split(url, "/")
    [host, portstr] = String.split(host_and_port,":")
    port = String.to_integer(portstr)
    %Configuration{ host: host, port: port, system_name: system_name }
  end
  def configure_papertrail_target(config) do
    system_name = Keyword.get(config, :system_name, nil)
    [ host, portstr ] = Keyword.get(config, :host) |> String.split(":")
    {port,_} = Integer.parse(portstr)
    %Configuration{ host: host, port: port, system_name: system_name }
  end

end
