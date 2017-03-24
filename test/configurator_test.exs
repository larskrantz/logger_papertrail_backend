defmodule LoggerPapertrailBackend.ConfiguratorTest do
  use ExUnit.Case, async: true
  alias LoggerPapertrailBackend.{Configuration, Configurator, ConfigurationError}
  doctest Configurator

  test "should raise if config is totally wrong" do
    assert_raise ConfigurationError, fn ->
      Configurator.configure_papertrail_target("hello world")
    end
  end
  test "should be able to use host-type configuration" do
    config = [ host: "somehost:2810", level: :info, system_name: "app" ]
    assert %Configuration{host: "somehost", port: 2810, system_name: "app"} == Configurator.configure_papertrail_target(config)
  end
  test "should be able to use url-format with papertrail as schema" do
    config = [ url: "papertrail://somehost:667/my_app", level: :info]
    assert %Configuration{host: "somehost", port: 667, system_name: "my_app"} == Configurator.configure_papertrail_target(config)
  end
  test "host-config from readme should work" do
    config = [
      host: "logs.papertrailapp.com:11",
      level: :warn,
      system_name: "Wizard",
      format: "$metadata $message"
    ]
    assert %Configuration{host: "logs.papertrailapp.com", port: 11, system_name: "Wizard"} == Configurator.configure_papertrail_target(config)
  end
  test "url-config from readme should work" do
    config = [
      url: "papertrail://logs.papertrailapp.com:11/Wizard",
      level: :warn,
      format: "$metadata $message"
    ]
    assert %Configuration{host: "logs.papertrailapp.com", port: 11, system_name: "Wizard"} == Configurator.configure_papertrail_target(config)
  end
  test "system_name is optional in host config" do
    config = [
      host: "somehost:22",
    ]
    assert %Configuration{host: "somehost", port: 22, system_name: nil} == Configurator.configure_papertrail_target(config)
  end
  test "system_name is optional in url config" do
    config = [
      url: "papertrail://somehost:22"
    ]
    assert %Configuration{host: "somehost", port: 22, system_name: nil} == Configurator.configure_papertrail_target(config)
  end
end
