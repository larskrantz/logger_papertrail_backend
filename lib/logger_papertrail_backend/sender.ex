defmodule LoggerPapertrailBackend.Sender do
  use GenServer

  @ip_udpdate_interval 60000
  def init({host,port}) do
    address = :inet.getaddr(String.to_char_list(host), :inet)
    case address do
      {:ok, ip} ->
        refresh_ip_periodically
        {:ok, %{ host: host, port: port, ip: ip } }
      _ -> {:stop, "Invalid host: #{host}"}
    end
  end

  def start_link(host,port) do
    GenServer.start_link(__MODULE__, {host,port}, name: __MODULE__)
  end

  def handle_cast({ :send, message }, state) do
    {:ok, socket} = :gen_udp.open(0)
    :gen_udp.send(socket, state.ip, state.port, message)
    :gen_udp.close(socket)
    { :noreply, state }
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:reconfigure, host, port}, state) do
    { :ok, ip } = :inet.getaddr(String.to_char_list(host), :inet)
    updated_state = %{ host: host, port: port, ip: ip }
    {:noreply, updated_state}
  end

  def handle_info(:update_ip, state) do
    { :ok, ip } = :inet.getaddr(String.to_char_list(state.host), :inet)
    refresh_ip_periodically
    updated_state = state |> Map.put(:ip, ip)
    { :noreply, updated_state }
  end

  def send(message) do
    :ok = GenServer.cast(__MODULE__, {:send, message})
  end
  def reconfigure(host,port) when is_binary(host) and is_integer(port) do
    :ok = GenServer.cast(__MODULE__, {:reconfigure, host, port})
  end
  def stop, do: GenServer.call(__MODULE__, :stop)

  defp refresh_ip_periodically, do: :timer.send_after(@ip_udpdate_interval, self, :update_ip)
end
