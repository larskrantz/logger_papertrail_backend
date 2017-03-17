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
end
