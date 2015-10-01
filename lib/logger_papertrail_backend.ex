defmodule LoggerPapertrailBackend do
  use Application

  def start(_type, _args) do
    LoggerPapertrailBackend.SenderSupervisor.start_link()
  end

end
