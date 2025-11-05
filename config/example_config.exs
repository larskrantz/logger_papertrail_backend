import Config

# This is an example configuration file showing both the modern Handler
# and legacy Backend approaches to logging to Papertrail.

# ==============================================================================
# OPTION 1: Modern Logger Handler (Elixir >= 1.15) - RECOMMENDED
# ==============================================================================
#
# The handler approach is configured at runtime. Add this to your application
# start callback or config/runtime.exs:
#
# :logger.add_handler(
#   :papertrail,
#   LoggerPapertrailBackend.Handler,
#   %{
#     config: %{
#       host: "logs.papertrailapp.com",
#       port: 12345,
#       system_name: "MyApp"
#     },
#     level: :info
#   }
# )
#
# Or using environment variables (recommended for production):
#
# :logger.add_handler(
#   :papertrail,
#   LoggerPapertrailBackend.Handler,
#   %{
#     config: %{
#       url: System.get_env("PAPERTRAIL_URL")
#       # Format: "papertrail://logs.papertrailapp.com:12345/MyApp"
#     },
#     level: String.to_existing_atom(System.get_env("LOG_LEVEL", "info"))
#   }
# )

# ==============================================================================
# OPTION 2: Legacy Logger Backend (All Elixir versions)
# ==============================================================================
#
# This can be configured in config.exs:

# Configure the backend settings
config :logger, :logger_papertrail_backend,
  # Option A: Direct host:port configuration
  host: "logs.papertrailapp.com:12345",
  system_name: "MyApp",
  level: :info,
  format: "$metadata $message",
  metadata: [:request_id, :user_id]

# Option B: URL configuration (cleaner for environment variables)
# config :logger, :logger_papertrail_backend,
#   url: System.get_env("PAPERTRAIL_URL"),
#   level: :info,
#   format: "$metadata $message"

# Add the backend to Logger
config :logger,
  backends: [:console, LoggerPapertrailBackend.Logger],
  level: :debug

# ==============================================================================
# ADVANCED: Multiple Handler Instances (Handler approach only)
# ==============================================================================
#
# You can add multiple handlers for different purposes:
#
# # Send all logs to primary system
# :logger.add_handler(:papertrail_all, LoggerPapertrailBackend.Handler, %{
#   config: %{host: "logs.papertrailapp.com", port: 12345, system_name: "MyApp"},
#   level: :debug
# })
#
# # Send only errors to dedicated error tracking
# :logger.add_handler(:papertrail_errors, LoggerPapertrailBackend.Handler, %{
#   config: %{host: "logs.papertrailapp.com", port: 12346, system_name: "MyApp-Errors"},
#   level: :error
# })
#
# # Send only specific domains to security system
# :logger.add_handler(:papertrail_security, LoggerPapertrailBackend.Handler, %{
#   config: %{host: "logs.papertrailapp.com", port: 12347, system_name: "MyApp-Security"},
#   filters: [
#     {:domain, {&:logger_filters.domain/2, {:log, :equal, [:auth, :security]}}}
#   ]
# })

# ==============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATION
# ==============================================================================

# You can also use import_config/1 for environment-specific settings:
# import_config "#{config_env()}.exs"

# Example dev.exs:
# import Config
# config :logger, :logger_papertrail_backend,
#   host: "logs.papertrailapp.com:12345",
#   system_name: "MyApp-Dev",
#   level: :debug

# Example prod.exs:
# import Config
# config :logger, :logger_papertrail_backend,
#   url: System.get_env("PAPERTRAIL_URL"),
#   level: :info
