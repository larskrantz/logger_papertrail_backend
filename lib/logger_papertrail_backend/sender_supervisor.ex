defmodule LoggerPapertrailBackend.SenderSupervisor do
  use Supervisor

  def start_link(host,port) do
    Supervisor.start_link(__MODULE__, [host,port])
  end

  def init(papertrail_opts) do
    children = [
      worker(LoggerPapertrailBackend.Sender, papertrail_opts, restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
