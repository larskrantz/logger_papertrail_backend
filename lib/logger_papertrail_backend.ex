defmodule LoggerPapertrailBackend do
  use GenEvent

    @moduledoc """
    This provides a backend for Logger that will send any messages to a syslogd.
    """

    @doc """
    Our module doesn't require any custom configuration, so just return the state.
    """
    def handle_call({:configure, _options}, state) do
      {:ok, :ok, state}
    end

    @doc """
    Match any errors that are logged.
    """
    def handle_event({_, gl, {Logger, msg, ts, md}}, state) when node(gl) == node() do
      IO.puts "TIMESTAMP:"
      IO.inspect ts
      IO.puts "MSG: #{msg}"
      IO.puts "MD:"
      IO.inspect md
      {:ok, state}
    end
    def handle_event(_data, state) do
      {:ok, state}
    end
end
