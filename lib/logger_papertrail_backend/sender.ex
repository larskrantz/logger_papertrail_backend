defmodule LoggerPapertrailBackend.Sender do
  def send(message, host, port) do
    {:ok, address} = :inet.getaddr(String.to_char_list(host), :inet)
    {:ok, socket} = :gen_udp.open(0)
    :gen_udp.send(socket, address, port, message)
    :gen_udp.close(socket)
  end
end
