defmodule LoggerPapertrailBackend.Sender do
  use GenServer

  @ip_update_interval_ms 60000
  def init() do
    {:ok, %{ host: nil, port: nil, ip: nil }}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

   def handle_cast({ :send, message }, %{ ip: ip, port: port} = state) when is_integer(port) and is_tuple(ip) do
    {:ok, socket} = :gen_udp.open(0)
    :gen_udp.send(socket, state.ip, state.port, message)
    :gen_udp.close(socket)
    { :noreply, state }
  end
  def handle_cast({ :send, message }, state), do: { :noreply, state }

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:reconfigure, host, port}, state) do
    ip = resolve_host(host)
    updated_state = %{ host: host, port: port, ip: ip }
    refresh_ip_in_intervalls
    {:noreply, updated_state}
  end

  def handle_info(:update_ip, %{ host: host } = state) when is_binary(host) do
    ip = resolve_host(host)
    updated_state = state |> Map.put(:ip, ip)
    refresh_ip_in_intervalls
    { :noreply, updated_state }
  end
  def handle_info(:update_ip, state), do: { :noreply, state }

  def send(message) do
    :ok = GenServer.cast(__MODULE__, {:send, message})
  end

  def reconfigure(host,port) when is_binary(host) and is_integer(port) do
    :ok = GenServer.cast(__MODULE__, {:reconfigure, host, port})
  end


  defp refresh_ip_in_intervalls, do: :timer.send_after(@ip_update_interval_ms, self, :update_ip)
  defp resolve_host(host) do
    { :ok, ip } = :inet.getaddr(String.to_char_list(host), :inet)
    ip
  end
end
