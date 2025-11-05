# Modern Logger Handler Implementation Example

This document shows what a modern Erlang `:logger` handler implementation would look like for this project.

## Current Architecture (gen_event)

```elixir
# User configuration
config :logger,
  backends: [LoggerPapertrailBackend.Logger]

# Implementation
defmodule LoggerPapertrailBackend.Logger do
  @behaviour :gen_event
  # ... gen_event callbacks
end
```

## Modern Architecture (handler)

### Configuration

```elixir
# In config.exs
config :logger,
  # Add Papertrail as a handler
  handlers: [
    papertrail: [
      module: LoggerPapertrailBackend.Handler,
      config: %{
        host: "logs.papertrailapp.com",
        port: 12345,
        system_name: "MyApp",
        level: :info
      }
    ]
  ]
```

### Handler Implementation

```elixir
defmodule LoggerPapertrailBackend.Handler do
  @moduledoc """
  Modern Logger handler using Erlang's :logger module.

  This replaces the old gen_event backend with a more efficient handler.
  """

  @doc """
  Called when handler is added.
  Returns {:ok, config} or {:error, reason}
  """
  def adding_handler(config) do
    # Initialize connection, validate config
    case validate_config(config) do
      :ok -> {:ok, config}
      error -> error
    end
  end

  @doc """
  Called when handler is removed.
  Cleanup resources.
  """
  def removing_handler(_config) do
    :ok
  end

  @doc """
  Called for configuration changes.
  """
  def changing_config(_set_or_update, _old_config, new_config) do
    {:ok, new_config}
  end

  @doc """
  Main callback - called for each log event.
  This is where the actual logging happens.
  """
  def log(log_event, config) do
    %{
      level: level,
      msg: msg,
      meta: meta
    } = log_event

    # Format and send the message
    formatted_msg = format_message(log_event, config)
    send_to_papertrail(formatted_msg, config)
  rescue
    error ->
      # Handler should never crash
      IO.puts(:stderr, "Papertrail handler error: #{inspect(error)}")
  end

  @doc """
  Filter callback - return :stop to prevent logging, :log to allow.
  This is more efficient than checking in log/2.
  """
  def filter_config(_config) do
    # Return filter functions
    []
  end

  # Private functions

  defp validate_config(config) do
    required = [:host, :port]

    if Enum.all?(required, &Map.has_key?(config, &1)) do
      :ok
    else
      {:error, {:missing_config, required}}
    end
  end

  defp format_message(log_event, config) do
    %{
      level: level,
      msg: {:string, message},
      meta: meta
    } = log_event

    # Build syslog format
    application = Map.get(meta, :application, Map.get(config, :system_name, "elixir"))
    procid = Map.get(meta, :module, "")

    # Use Syslog format (RFC 5424 or RFC 3164)
    build_syslog_message(level, application, procid, message)
  end

  defp build_syslog_message(level, application, procid, message) do
    priority = severity_to_priority(level)
    timestamp = DateTime.utc_now() |> Calendar.strftime("%b %d %H:%M:%S")

    # RFC 3164 format
    "<#{priority}>#{timestamp} #{application} #{procid}: #{message}"
  end

  defp severity_to_priority(level) do
    # Syslog severity levels
    case level do
      :emergency -> 0
      :alert -> 1
      :critical -> 2
      :error -> 3
      :warning -> 4
      :notice -> 5
      :info -> 6
      :debug -> 7
      _ -> 6
    end
  end

  defp send_to_papertrail(message, config) do
    host = Map.fetch!(config, :host)
    port = Map.fetch!(config, :port)

    # Send via UDP (would use GenServer for connection management)
    LoggerPapertrailBackend.Sender.send(message, host, port)
  end
end
```

### Runtime Handler Management

```elixir
# Add handler at runtime
:logger.add_handler(
  :papertrail,
  LoggerPapertrailBackend.Handler,
  %{
    level: :info,
    host: "logs.papertrailapp.com",
    port: 12345,
    system_name: "MyApp",
    filters: [
      # Only log from specific domains
      domain: {&:logger_filters.domain/2, {:log, :equal, [:my_app]}}
    ]
  }
)

# Remove handler
:logger.remove_handler(:papertrail)

# Update configuration
:logger.update_handler_config(:papertrail, %{level: :debug})

# Get handler config
{:ok, config} = :logger.get_handler_config(:papertrail)
```

## Advantages of Handler Implementation

### 1. Performance
- Handlers can process events asynchronously
- Better backpressure handling
- Optimized for high-throughput scenarios

### 2. Filtering Before Formatting
```elixir
# With handlers, filtering happens BEFORE expensive formatting
config :logger, :papertrail,
  level: :warning,
  filters: [
    # Stop debug logs before they reach the handler
    {:level, {&:logger_filters.level/2, {:stop, :lt, :warning}}}
  ]
```

### 3. Domain Support
```elixir
# Log with domain
Logger.info("User signed in", domain: [:auth])

# Filter by domain in handler
filters: [
  domain: {&:logger_filters.domain/2, {:stop, :not_equal, [:auth, :api]}}
]
```

### 4. Multiple Handlers Per Backend
```elixir
# Send errors to one Papertrail destination
# Send all logs to another
:logger.add_handler(:papertrail_errors, Handler, %{
  host: "errors.example.com",
  port: 514,
  level: :error
})

:logger.add_handler(:papertrail_all, Handler, %{
  host: "logs.example.com",
  port: 515,
  level: :debug
})
```

### 5. Better Integration with OTP
```elixir
# All Erlang/OTP logs automatically included
# No special configuration needed for:
# - :gen_server crashes
# - :supervisor restarts
# - :gen_statem events
# - Process labels (OTP 27+)
```

## Migration Strategy

For this project, we have three options:

### Option 1: Keep Current Implementation (Recommended for now)
- ✅ Works with all Elixir versions
- ✅ No breaking changes for users
- ✅ Well-tested codebase
- ⚠️ Uses "legacy" API (but still supported)

### Option 2: Add Handler Implementation (Dual Support)
- Create new `LoggerPapertrailBackend.Handler` module
- Keep existing `Logger` module for backwards compatibility
- Let users choose which to use
- Document both approaches

### Option 3: Full Migration to Handler Only
- ⚠️ Breaking change for users
- Would require version bump to 2.0
- Only supports Elixir >= 1.15
- Better long-term maintenance

## Recommendation

**Keep the current gen_event implementation** because:
1. It's well-tested and works
2. Many projects still use the old API
3. Backwards compatibility is maintained by Elixir team
4. The `:logger_backends` package provides continued support

**Consider adding handler support** in a future release as an opt-in feature for users who want:
- Better performance
- Native OTP integration
- Advanced filtering capabilities
- Multiple handler instances

## References

- [Elixir 1.15 Changelog](https://hexdocs.pm/elixir/1.15/changelog.html)
- [Erlang :logger documentation](https://www.erlang.org/doc/man/logger.html)
- [Logger Handlers Guide](https://www.erlang.org/doc/apps/kernel/logger_chapter.html)
