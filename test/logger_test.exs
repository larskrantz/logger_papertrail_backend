defmodule LoggerPapertrailBackend.LoggerTest do
  use ExUnit.Case, async: true
  require Logger

  @system_name "test_system_name"
  @port 29123

  setup do
    :ok = Application.put_env(:logger, :backends, [ LoggerPapertrailBackend.Logger ])
    :ok = Application.put_env(:logger, :logger_papertrail_backend,
      url: "papertrail://localhost:#{@port}/#{@system_name}")
    Application.ensure_started(:logger)
    MockPapertrailServer.start(@port, self())
    :ok
  end

  test "will send message" do
    log = "Will send this debugging message"
    Logger.debug(log)
    assert_receive {:ok, message}, 5000
    assert String.contains?(message, log)
  end

  test "will have system name in the message" do
    Logger.warn("Well, hello")
    assert_receive {:ok, message}, 5000
    assert String.contains?(message, @system_name)
  end

  test "can overwrite system name" do
    Logger.warn("Look, another system name", system_name: "a_new_system_name")
    assert_receive {:ok, message}, 5000
    refute String.contains?(message, @system_name)
    assert String.contains?(message, "a_new_system_name")
  end
end
