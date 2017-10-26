defmodule AirElixir.TowerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: {:global,  __MODULE__})
  end

  def start_control_tower(name) do
    Supervisor.start_child({:global, __MODULE__}, [name])
  end

  def init(_opts) do
    children = [ worker(AirElixir.ControlTower, []) ] # TODO add Control Tower and Planes here depending on the node

    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
