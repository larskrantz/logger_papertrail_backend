# LoggerPapertrailBackend

[![Hex.pm](https://img.shields.io/hexpm/v/logger_papertrail_backend.svg?maxAge=2592000)](https://hex.pm/packages/logger_papertrail_backend)
[![Hex.pm](https://img.shields.io/hexpm/dt/logger_papertrail_backend.svg)](https://hex.pm/packages/logger_papertrail_backend)
[![CI](https://github.com/larskrantz/logger_papertrail_backend/actions/workflows/ci.yml/badge.svg)](https://github.com/larskrantz/logger_papertrail_backend/actions/workflows/ci.yml)

A [Papertrail](https://papertrailapp.com) backend for [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html).

[Changelog](CHANGELOG.md)

## Two Ways to Use This Package

This package supports **two different approaches** for logging to Papertrail:

1. **Logger Handler** (Modern, Elixir >= 1.15) - Uses Erlang's `:logger` infrastructure
2. **Logger Backend** (Legacy, all Elixir versions) - Uses the traditional `:gen_event` system

**Which should you use?**

- **Use the Handler** if you're on Elixir >= 1.15 and want better performance, advanced filtering, or multiple handler instances
- **Use the Backend** if you need compatibility with older Elixir versions or prefer the traditional approach

Both approaches work great and will continue to be supported!

## Installation

Available in [Hex](https://hex.pm/packages/logger_papertrail_backend). The package can be installed as:

* Add `logger_papertrail_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:logger_papertrail_backend, "~> 1.1"}]
end
```

* Ensure `Logger` is in `extra_applications`:

```elixir
def application do
  [extra_applications: [:logger]]
end
```

## Configuration

### Option 1: Modern Logger Handler (Elixir >= 1.15)

The handler approach uses Erlang's native `:logger` infrastructure for better performance and more features.

* In your `config.exs`:

```elixir
# Add the Papertrail handler at runtime in your application start
:logger.add_handler(
  :papertrail,
  LoggerPapertrailBackend.Handler,
  %{
    config: %{
      host: "logs.papertrailapp.com",
      port: 12345,  # Your Papertrail port
      system_name: "MyApp"
    },
    level: :info
  }
)
```

**Or** configure via runtime.exs or releases:

```elixir
# In your config/runtime.exs
:logger.add_handler(
  :papertrail,
  LoggerPapertrailBackend.Handler,
  %{
    config: %{
      url: System.get_env("PAPERTRAIL_URL"),  # "papertrail://logs.papertrailapp.com:12345/MyApp"
    },
    level: :info
  }
)
```

**Handler Configuration Options:**

* `:host` - Papertrail host (required if not using `:url`)
* `:port` - Papertrail port (required if not using `:url`)
* `:system_name` - System name in logs (optional, defaults to application name)
* `:url` - Alternative format: `"papertrail://logs.papertrailapp.com:12345/SystemName"`
* `:level` - Minimum log level (`:debug`, `:info`, `:warning`, `:error`)

**Handler Advantages:**

* Better performance under high load
* Support for multiple handler instances with different configurations
* Advanced filtering with Erlang's `:logger_filters`
* Domain-based logging support
* Native OTP integration

### Option 2: Legacy Logger Backend (All Elixir Versions)

The traditional backend approach using `:gen_event`. This works on all Elixir versions and is fully supported.

* In your `config.exs` (or in your `#{Mix.env}.exs`-files):

```elixir
config :logger, :logger_papertrail_backend,
  host: "logs.papertrailapp.com:12345",
  level: :warn,
  system_name: "Wizard",
  metadata_filter: [],
  format: "$metadata $message"
```

Alternatively use `:url` for shorter config:

```elixir
config :logger, :logger_papertrail_backend,
  url: "papertrail://logs.papertrailapp.com:12345/my_system_name",
  level: :warn,
  format: "$metadata $message"
```

Then configure Logger to use the backend:

```elixir
config :logger,
  backends: [:console, LoggerPapertrailBackend.Logger],
  level: :debug
```

_Note: if you have an umbrella project, use your top `config.exs`._

**Backend Configuration Options:**

* `:host` - Papertrail host with port (required if not using `:url`), e.g., `"logs.papertrailapp.com:12345"`
* `:port` - Can be included in host or separate
* `:system_name` - System name in logs (optional, defaults to current application name)
* `:url` - Alternative format: `"papertrail://logs.papertrailapp.com:12345/system_name"`
* `:level` - Minimum log level (overrides global Logger setting)
* `:format` - Message format, defaults to `[$level] $levelpad$metadata $message`. See [Logger.Formatter](https://hexdocs.pm/logger/Logger.Formatter.html)
* `:metadata_filter` - Metadata terms that must be present to log. See [LoggerFileBackend](https://github.com/onkel-dirtus/logger_file_backend#filtering-specific-metadata-terms)
* `:colors` - Color configuration (see Logger console backend)
* `:metadata` - Metadata to include (see Logger console backend)

## Getting Started with Papertrail

1. Sign up for [Papertrail](https://papertrailapp.com)
2. In your Papertrail dashboard, click "Add System"
3. Note your Papertrail host and port (e.g., `logs2.papertrailapp.com:12345`)
4. Configure this package using either the Handler or Backend approach above
5. Start your application and watch logs appear in Papertrail!

## Example output

`Oct 02 14:19:04 Wizard UpptecSlack.SlackBot:  [info]   Successfully authenticated as user "wizard" on team "Upptec"`

Papertrail sets the timestamp when the message arrives. `Wizard` is the `:system_name`. `UpptecSlack.SlackBot` is the module sending the log. `[info]` is the log level.

## Advanced Handler Features (Elixir >= 1.15)

### Multiple Handlers

Send different log levels to different Papertrail systems:

```elixir
# Send all logs to main system
:logger.add_handler(:papertrail_all, LoggerPapertrailBackend.Handler, %{
  config: %{host: "logs.papertrailapp.com", port: 12345, system_name: "MyApp"},
  level: :debug
})

# Send only errors to error-specific system
:logger.add_handler(:papertrail_errors, LoggerPapertrailBackend.Handler, %{
  config: %{host: "logs.papertrailapp.com", port: 12346, system_name: "MyApp-Errors"},
  level: :error
})
```

### Domain-Based Filtering

```elixir
# Log with domain
Logger.info("User logged in", domain: [:auth])

# Configure handler to only log from specific domains
:logger.add_handler(:papertrail, LoggerPapertrailBackend.Handler, %{
  config: %{host: "logs.papertrailapp.com", port: 12345},
  filters: [
    {:domain, {&:logger_filters.domain/2, {:log, :equal, [:auth, :api]}}}
  ]
})
```
