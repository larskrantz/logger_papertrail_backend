defmodule LoggerPapertrailBackend do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      worker(LoggerPapertrailBackend.Sender, [])
    ]
    opts = [strategy: :one_for_one, name: LoggerPapertrailBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
