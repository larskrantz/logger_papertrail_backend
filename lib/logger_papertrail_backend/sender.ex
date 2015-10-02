defmodule LoggerPapertrailBackend.Sender do
  use GenServer

  @ip_update_interval_ms 60000
  def init(_), do: init()
  def init() do
    refresh_ips_in_intervalls
    {:ok, %{}}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

   def handle_cast({ :send, message, host, port}, state) when is_integer(port) and is_binary(host) and is_binary(message) do
    { ip, updated_state } = state |> resolve(host)
    {:ok, socket} = :gen_udp.open(0)
    :gen_udp.send(socket, ip, port, message)
    :gen_udp.close(socket)
    { :noreply, updated_state }
  end
  def handle_cast({ :send, _message, _host, _port }, state), do: { :noreply, state }

  def handle_info(:update_ip, state) do
    updated_state = state |> Enum.reduce(%{},&refresh_ip/2)
    refresh_ips_in_intervalls
    { :noreply, updated_state }
  end

  def send(message, host, port) do
    :ok = GenServer.cast(__MODULE__, {:send, message, host, port})
  end

  defp refresh_ips_in_intervalls, do: :timer.send_after(@ip_update_interval_ms, self, :update_ip)
  defp refresh_ip({ host, _ip }, state) do
    ip = resolve_host(host)
    state |> Map.put(host, ip)
  end

  defp resolve(state, host) do
    case Map.fetch(state, host) do
      {:ok, ip} -> {ip, state}
      _ -> state |> resolve_add_host(host)
    end
  end
  defp resolve_host(host) do
    { :ok, ip } = :inet.getaddr(String.to_char_list(host), :inet)
    ip
  end
  defp resolve_add_host(state, host) do
    ip = resolve_host(host)
    new_state = Map.put(state, host, ip)
    { ip, new_state }
  end
end
