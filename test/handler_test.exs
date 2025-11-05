defmodule LoggerPapertrailBackend.HandlerTest do
  use ExUnit.Case, async: false
  require Logger

  @system_name "test_handler_system"
  @port 29124
  @handler_id :test_papertrail_handler

  setup do
    # Start the application to ensure Sender is running
    Application.ensure_all_started(:logger_papertrail_backend)

    # Start mock server
    MockPapertrailServer.start(@port, self())

    # Remove handler if it exists from previous tests
    :logger.remove_handler(@handler_id)

    # Add handler
    {:ok, _} =
      :logger.add_handler(
        @handler_id,
        LoggerPapertrailBackend.Handler,
        %{
          config: %{
            host: "localhost",
            port: @port,
            system_name: @system_name
          },
          level: :debug
        }
      )

    on_exit(fn ->
      :logger.remove_handler(@handler_id)
    end)

    :ok
  end

  test "handler sends message via UDP" do
    log = "Test message from handler"
    Logger.debug(log)
    assert_receive {:ok, message}, 5000
    assert String.contains?(message, log)
  end

  test "handler includes system name in message" do
    Logger.warning("Handler test message")
    assert_receive {:ok, message}, 5000
    assert String.contains?(message, @system_name)
  end

  test "handler respects log level" do
    # Update handler to only log :warning and above
    :logger.set_handler_config(@handler_id, :level, :warning)

    Logger.debug("Should not appear")
    Logger.info("Also should not appear")
    Logger.warning("Should appear")

    assert_receive {:ok, message}, 5000
    assert String.contains?(message, "Should appear")
    refute_received {:ok, _}
  end

  test "handler can be configured with URL" do
    handler_id = :test_url_handler

    {:ok, _} =
      :logger.add_handler(
        handler_id,
        LoggerPapertrailBackend.Handler,
        %{
          config: %{
            url: "papertrail://localhost:#{@port}/url_test_system"
          },
          level: :info
        }
      )

    Logger.info("URL config test")
    assert_receive {:ok, message}, 5000
    assert String.contains?(message, "URL config test")
    assert String.contains?(message, "url_test_system")

    :logger.remove_handler(handler_id)
  end

  test "handler validates config on adding" do
    # Missing required config
    result =
      :logger.add_handler(
        :invalid_handler,
        LoggerPapertrailBackend.Handler,
        %{
          config: %{
            # Missing host and port
            system_name: "test"
          }
        }
      )

    assert {:error, _} = result
  end

  test "handler can be updated at runtime" do
    Logger.info("Before update")
    assert_receive {:ok, message1}, 5000
    assert String.contains?(message1, @system_name)

    # Update config with new system name
    :logger.update_handler_config(@handler_id, %{
      config: %{
        host: "localhost",
        port: @port,
        system_name: "updated_system"
      }
    })

    Logger.info("After update")
    assert_receive {:ok, message2}, 5000
    assert String.contains?(message2, "updated_system")
    refute String.contains?(message2, @system_name)
  end

  test "handler includes module metadata" do
    Logger.info("Module test")
    assert_receive {:ok, message}, 5000
    # The message should include the module name
    assert String.contains?(message, "HandlerTest")
  end

  describe "multiple handlers" do
    test "can have multiple handlers with different configs" do
      handler2_id = :second_handler
      port2 = 29125
      system2 = "second_system"

      MockPapertrailServer.start(port2, self())

      {:ok, _} =
        :logger.add_handler(
          handler2_id,
          LoggerPapertrailBackend.Handler,
          %{
            config: %{
              host: "localhost",
              port: port2,
              system_name: system2
            },
            level: :info
          }
        )

      Logger.info("Multi-handler test")

      # Should receive from both handlers
      assert_receive {:ok, message1}, 5000
      assert_receive {:ok, message2}, 5000

      messages = [message1, message2]
      assert Enum.any?(messages, &String.contains?(&1, @system_name))
      assert Enum.any?(messages, &String.contains?(&1, system2))

      :logger.remove_handler(handler2_id)
    end
  end

  describe "error handling" do
    test "handler doesn't crash on invalid message" do
      # Handler should handle errors gracefully
      Logger.info("Normal message")
      assert_receive {:ok, _}, 5000

      # The handler should continue working even if there were issues
      Logger.info("Another message")
      assert_receive {:ok, _}, 5000
    end
  end

  describe "configuration validation" do
    test "adding_handler/1 validates host and port" do
      result =
        LoggerPapertrailBackend.Handler.adding_handler(%{
          config: %{host: "localhost", port: 12345}
        })

      assert {:ok, _} = result
    end

    test "adding_handler/1 validates URL config" do
      result =
        LoggerPapertrailBackend.Handler.adding_handler(%{
          config: %{url: "papertrail://localhost:12345/test"}
        })

      assert {:ok, _} = result
    end

    test "adding_handler/1 rejects invalid config" do
      result =
        LoggerPapertrailBackend.Handler.adding_handler(%{
          config: %{invalid: "config"}
        })

      assert {:error, _} = result
    end
  end
end
