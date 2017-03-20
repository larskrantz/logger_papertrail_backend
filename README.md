# LoggerPapertrailBackend
[![Hex.pm](https://img.shields.io/hexpm/v/logger_papertrail_backend.svg?maxAge=2592000)](https://hex.pm/packages/logger_papertrail_backend)
[![Hex.pm](https://img.shields.io/hexpm/dt/logger_papertrail_backend.svg)](https://hex.pm/packages/logger_papertrail_backend)
[![Build Status](https://travis-ci.org/larskrantz/logger_papertrail_backend.svg?branch=master)](https://travis-ci.org/larskrantz/logger_papertrail_backend)

A [Papertrail](https://papertrailapp.com) backend for [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html).

[Changelog](CHANGELOG.md)


## Installation

Available in [Hex](https://hex.pm/packages/logger_papertrail_backend). The package can be installed as:

* Add `logger_papertrail_backend` to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [{:logger_papertrail_backend, "~> 0.1.2"}]
end
```
* Ensure `logger` and `logger_papertrail_backend` is started before your application (pre Elixir 1.4):
```elixir
def application do
  [applications: [:logger, :logger_papertrail_backend]]
end
```
* Or after Elixir 1.4, just ensure `Logger` is in `extra_applications`:
```elixir
def application do
  [extra_applications: [:logger]]
end
```
* In your `config.exs` (or in your `#{Mix.env}.exs`-files):
```elixir
config :logger, :logger_papertrail_backend,
  host: "logs.papertrailapp.com:<port>",
  level: :warn,
  system_name: "Wizard",
  format: "$metadata $message"
```
  Alternatively use :url for shorter config.
  Prepend with "papertrail://" or "syslog://" then host:port/system_name. We normally set an ENV-var: `url: System.get_env("PAPERTRAIL_URL")` or ` url: "${PAPERTRAIL_URL}",` if building releases with [Distillery](https://github.com/bitwalker/distillery) and `REPLACE_OS_VARS=true`.
```elixir
config :logger, :logger_papertrail_backend,
  url: "papertrail://logs.papertrailapp.com:<port>/<system_name>",
  level: :warn,
  format: "$metadata $message"
```
  Then config `:logger` to use the `LoggerPapertrailBackend.Logger`:
```elixir
config :logger,
  backends: [ :console,
    LoggerPapertrailBackend.Logger
  ],
  level: :debug
```
  _Note: if you have an umbrella project, use your top `config.exs`._

  * (Required) Follow "Add System" in your Papertrail dashboard to get `:host` values
  * (Optional) Set `:level` for this backend (overides global `:logger`-setting )
  * (Optional) Set specific `:system_name` in Papertrail, defaults to current application-name
  * (Optional) Set :format, defaults to `[$level] $levelpad$metadata $message`, see [Logger.Formatter](http://elixir-lang.org/docs/stable/logger/Logger.Formatter.html)
  * Other supported options in config are `:colors`, `:metadata`. See :console-docs in [Elixir.Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)




## Example output:

`Oct 02 14:19:04 Wizard UpptecSlack.SlackBot:  [info]   Successfully authenticated as user "wizard" on team "Upptec"`


Papertrail sets timestamp when message arrives. `Wizard` is `:system_name`. `UpptecSlack.SlackBot` is the module sending the log. `[Info]` is level.
