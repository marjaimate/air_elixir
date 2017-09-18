defmodule AirElixir do
  use Application

  def start(_type, args) do
    AirElixir.Supervisor.start_link(args)
  end

  def stop(_) do
    :ok
  end
end
