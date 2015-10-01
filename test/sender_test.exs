defmodule TestServer do
  def start(port, receiver), do: spawn(fn() -> server(port, receiver) end)

  def server(port, receiver) do
    {:ok, socket} = :gen_udp.open(port, [:binary])
    once(socket, receiver)
  end
  def once(socket, receiver) do
    receive do
      {:udp, ^socket, _host, _port, bin} -> send(receiver, {:ok, bin})
      _ -> :fail
    end
  end
end
defmodule SenderTest do
  use ExUnit.Case
  test "will send a message to the server" do
    port = 28000
    host = "localhost"
    TestServer.start(port,self)
    {:ok, _pid} = LoggerPapertrailBackend.SenderSupervisor.start_link(host,port)
    LoggerPapertrailBackend.Sender.send("Hello UDP!")
    assert_receive {:ok, "Hello UDP!"}, 5000
    LoggerPapertrailBackend.Sender.stop
  end
end
