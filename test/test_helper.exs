defmodule MockPapertrailServer do
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
ExUnit.start()
