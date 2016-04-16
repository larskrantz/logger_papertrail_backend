defmodule SenderTest do
  use ExUnit.Case
  test "will send a message to the server" do
    port = 28000
    host = "localhost"
    MockPapertrailServer.start(port,self)
    LoggerPapertrailBackend.Sender.send("Hello UDP!", host, port)
    assert_receive {:ok, "Hello UDP!"}, 5000
  end
end
