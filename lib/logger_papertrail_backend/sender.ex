defmodule LoggerPapertrailBackend.Sender do
  use GenServer

  defmodule State do
    defstruct hosts: %{}
  end

  @ip_update_interval_ms 60_000
  def init(_), do: init()
  def init() do
    :timer.send_interval(@ip_update_interval_ms, :update_ip)
    {:ok, %State{}}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

   def handle_cast({ :send, message, host, port}, state) when is_integer(port) and is_binary(host) and is_binary(message) do
    { ip, new_state } = get_ip_address(state, host)
    {:ok, socket} = :gen_udp.open(0)
    :gen_udp.send(socket, ip, port, message)
    :gen_udp.close(socket)
    { :noreply, new_state }
  end
  def handle_cast({ :send, _message, _host, _port }, state), do: { :noreply, state }

  def handle_info(:update_ip, state) do
    updated_state = refresh_ips(state)

    { :noreply, updated_state }
  end

  def send(message, host, port) do
    :ok = GenServer.cast(__MODULE__, {:send, message, host, port})
  end

  defp refresh_ips(%State{hosts: hosts} = state), do: refresh_ips(Map.keys(hosts), state)
  defp refresh_ips([], state), do: state
  defp refresh_ips([ host | tail], state) do
    { _, updated_state } = resolve_add_host(state, host)
    refresh_ips(tail, updated_state)
  end

  defp get_ip_address(%State{hosts: hosts} = state, host) do
    case Map.fetch(hosts, host) do
      {:ok, ip} -> {ip, state}
      _ -> resolve_add_host(state, host)
    end
  end
  defp resolve_host(host) do
    case :inet.getaddr(String.to_char_list(host), :inet) do
      { :ok, ip } -> ip
      _ -> nil
    end
  end
  defp resolve_add_host(state, host) do
    case resolve_host(host) do
      nil ->  last_resolved_ip = Map.get(state.hosts, host)
              { last_resolved_ip, state }
      ip ->   new_hosts = Map.put(state.hosts, host, ip)
              new_state = %State{ state | hosts: new_hosts }
              { ip, new_state }
      end
  end
end
