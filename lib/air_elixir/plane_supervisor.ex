defmodule AirElixir.PlaneSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_plane(control_tower) do
    Supervisor.start_child(__MODULE__, [control_tower])
  end

  def terminate_child(plane) do
    Supervisor.terminate_child(__MODULE__, plane)
  end

  def init(_opts) do
    children = [ worker(AirElixir.Plane, [], restart: :temporary, shutdown: :brutal_kill) ]

    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
