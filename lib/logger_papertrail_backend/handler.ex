defmodule LoggerPapertrailBackend.Handler do
  @moduledoc """
  Modern Erlang :logger handler for Papertrail.

  This handler uses the Erlang/OTP :logger infrastructure introduced in OTP 21
  and soft-adopted by Elixir 1.15+. It provides better performance and more
  features than the legacy gen_event backend.

  ## Configuration

  Add the handler in your config.exs:

      config :logger,
        handlers: [
          papertrail: [
            module: LoggerPapertrailBackend.Handler,
            config: %{
              host: "logs.papertrailapp.com",
              port: 12345,
              system_name: "MyApp"
            },
            level: :info
          ]
        ]

  Or configure at runtime:

      :logger.add_handler(
        :papertrail,
        LoggerPapertrailBackend.Handler,
        %{
          config: %{
            host: "logs.papertrailapp.com",
            port: 12345,
            system_name: "MyApp"
          },
          level: :info
        }
      )

  ## Handler Configuration

  The handler config map supports:

  * `:host` - Papertrail host (required, e.g., "logs.papertrailapp.com")
  * `:port` - Papertrail port (required, e.g., 12345)
  * `:system_name` - System name in logs (optional, defaults to application name)
  * `:url` - Alternative format: "papertrail://logs.papertrailapp.com:12345/SystemName"

  ## Advantages over gen_event backend

  * Better performance under high load
  * Native OTP integration
  * Advanced filtering capabilities
  * Support for multiple handler instances
  * Domain-based logging support
  """

  import LoggerPapertrailBackend.Configurator

  @doc """
  Called when the handler is added to the logger.

  Validates configuration and ensures the Sender process is available.
  Returns `{:ok, config}` on success or `{:error, reason}` on failure.
  """
  def adding_handler(%{config: config} = handler_config) do
    case validate_config(config) do
      :ok ->
        # Ensure the Sender GenServer is started
        case Process.whereis(LoggerPapertrailBackend.Sender) do
          nil ->
            {:error, :sender_not_started}

          _pid ->
            {:ok, handler_config}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def adding_handler(_config) do
    {:error, :missing_config}
  end

  @doc """
  Called when the handler is removed from the logger.

  Performs cleanup if necessary. Currently a no-op as the Sender GenServer
  may be used by other handlers or the legacy backend.
  """
  def removing_handler(_config) do
    :ok
  end

  @doc """
  Called when handler configuration is changed.

  Validates the new configuration and returns `{:ok, new_config}` or `{:error, reason}`.
  """
  def changing_config(:set, _old_config, new_config) do
    adding_handler(new_config)
  end

  def changing_config(:update, old_config, new_config) do
    merged_config = Map.merge(old_config, new_config)
    adding_handler(merged_config)
  end

  @doc """
  Main log callback - called for each log event that passes filters.

  Formats the log message and sends it to Papertrail via UDP.
  This function must never crash, as it would affect the entire logging system.
  """
  def log(%{level: level, msg: msg, meta: meta} = _log_event, %{config: config}) do
    try do
      # Extract and format the message
      message = format_message(msg)

      # Extract metadata
      application = extract_application(meta, config)
      procid = extract_procid(meta)

      # Get timestamp (Erlang logger provides it in microseconds since epoch)
      timestamp = extract_timestamp(meta)

      # Build the syslog message using existing MessageBuilder
      formatted_msg =
        LoggerPapertrailBackend.MessageBuilder.build(
          message,
          level,
          application,
          timestamp,
          procid
        )

      # Get host and port from config
      target = configure_papertrail_target(config)

      # Send to Papertrail
      LoggerPapertrailBackend.Sender.send(formatted_msg, target.host, target.port)
    rescue
      error ->
        # Log to stderr but never crash
        IO.puts(
          :stderr,
          "LoggerPapertrailBackend.Handler error: #{inspect(error)}\n#{Exception.format_stacktrace()}"
        )
    end
  end

  # Handle case where config is not properly structured
  def log(_log_event, _config) do
    :ok
  end

  # Private functions

  defp validate_config(config) when is_map(config) do
    # Check if we have either url or host+port
    cond do
      Map.has_key?(config, :url) ->
        :ok

      Map.has_key?(config, :host) and Map.has_key?(config, :port) ->
        :ok

      Map.has_key?(config, "host") and Map.has_key?(config, "port") ->
        :ok

      true ->
        {:error, {:missing_config, "Required: either :url or :host and :port"}}
    end
  end

  defp validate_config(_config) do
    {:error, {:invalid_config, "Config must be a map"}}
  end

  # Format the message part of the log event
  defp format_message({:string, chardata}), do: IO.chardata_to_string(chardata)
  defp format_message({:report, report}), do: format_report(report)
  defp format_message({format, args}), do: :io_lib.format(format, args) |> IO.chardata_to_string()

  defp format_report(report) when is_map(report) do
    # Format map reports nicely
    report
    |> Enum.map(fn {k, v} -> "#{k}=#{inspect(v)}" end)
    |> Enum.join(" ")
  end

  defp format_report(report) when is_list(report) do
    # Handle keyword list reports
    if Keyword.keyword?(report) do
      report
      |> Enum.map(fn {k, v} -> "#{k}=#{inspect(v)}" end)
      |> Enum.join(" ")
    else
      inspect(report)
    end
  end

  defp format_report(report), do: inspect(report)

  # Extract application/system name from metadata or config
  defp extract_application(meta, config) do
    # Priority: metadata > config > default
    meta
    |> Map.get(:system_name)
    |> case do
      nil -> extract_from_config(config)
      name -> name
    end
  end

  defp extract_from_config(config) do
    config
    |> Map.get(:system_name, config |> Map.get("system_name"))
    |> case do
      nil -> extract_from_domain(config)
      name -> to_string(name)
    end
  end

  defp extract_from_domain(config) do
    # If using URL configuration, parse it
    case Map.get(config, :url) || Map.get(config, "url") do
      nil ->
        # Default to the current application name
        Application.get_application(__MODULE__) || "elixir"

      _url ->
        # Let configurator handle it, it will extract system_name from URL
        target = configure_papertrail_target(config)
        target.system_name || "elixir"
    end
  end

  # Extract process identifier from metadata
  defp extract_procid(meta) do
    cond do
      Map.has_key?(meta, :module) ->
        Map.get(meta, :module)

      Map.has_key?(meta, :mfa) ->
        case Map.get(meta, :mfa) do
          {mod, fun, arity} -> "#{mod}.#{fun}/#{arity}"
          other -> inspect(other)
        end

      true ->
        ""
    end
  end

  # Extract and convert timestamp to format expected by MessageBuilder
  defp extract_timestamp(meta) do
    # Erlang logger provides timestamp in microseconds since epoch
    time = Map.get(meta, :time, :os.system_time(:microsecond))

    # Convert microseconds to Erlang datetime tuple
    seconds = div(time, 1_000_000)
    datetime = :calendar.gregorian_seconds_to_datetime(seconds + 62_167_219_200)

    # MessageBuilder expects {{year, month, day}, {hour, minute, second}}
    datetime
  end
end
