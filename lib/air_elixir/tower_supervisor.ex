defmodule AirElixir.TowerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_control_tower(name, number_of_landing_strips) do
    Supervisor.start_child(__MODULE__, [name, number_of_landing_strips])
  end

  def init(_opts) do
    children = [ worker(AirElixir.ControlTower, []) ] # TODO add Control Tower and Planes here depending on the node

    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
