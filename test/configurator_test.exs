defmodule LoggerPapertrailBackend.ConfiguratorTest do
  use ExUnit.Case, async: true
  doctest LoggerPapertrailBackend.Configurator

  test "should raise ConfigurationError if url is not supported" do
    assert_raise LoggerPapertrailBackend.ConfigurationError, "Url in format 'http://foo.bar:80' is not supported as configuration. Please check docs.", fn ->
      LoggerPapertrailBackend.Configurator.configure_papertrail_target(url: "http://foo.bar:80")
    end
  end
  test "should raise if config is totally wrong" do
    assert_raise LoggerPapertrailBackend.ConfigurationError, fn ->
      LoggerPapertrailBackend.Configurator.configure_papertrail_target("hello world")
    end
  end
  test "should be able to use host-type configuration" do
    config = [ host: "somehost:2810", level: :info, system_name: "app" ]
    assert %LoggerPapertrailBackend.Configuration{host: "somehost", port: 2810, system_name: "app"} == LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
  end
  test "should be able to use url-format with papertrail as schema" do
    config = [ url: "papertrail://somehost:667/my_app", level: :info]
    assert %LoggerPapertrailBackend.Configuration{host: "somehost", port: 667, system_name: "my_app"} == LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
  end
  test "host-config from readme should work" do
    config = [
      host: "logs.papertrailapp.com:11",
      level: :warn,
      system_name: "Wizard",
      format: "$metadata $message"
    ]
    assert %LoggerPapertrailBackend.Configuration{host: "logs.papertrailapp.com", port: 11, system_name: "Wizard"} == LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
  end
  test "url-config from readme should work" do
    config = [
      url: "papertrail://logs.papertrailapp.com:11/Wizard",
      level: :warn,
      format: "$metadata $message"
    ]
    assert %LoggerPapertrailBackend.Configuration{host: "logs.papertrailapp.com", port: 11, system_name: "Wizard"} == LoggerPapertrailBackend.Configurator.configure_papertrail_target(config)
  end
end
