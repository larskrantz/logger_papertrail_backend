defmodule LoggerPapertrailBackend.SenderSupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(LoggerPapertrailBackend.Sender, [], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
