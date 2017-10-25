defmodule AirElixir do
  use Application

  def start(_type, args) do
    return_sup = AirElixir.TowerSupervisor.start_link(args)
    airports = Application.get_env(:air_elixir, :airports)
    # Add airports
    airports
    |> List.foldl([], fn(name, acc) -> acc ++ [AirElixir.TowerSupervisor.start_control_tower(name)] end)

    airports
    |> List.foldl([], fn(name, acc) -> acc ++ [AirElixir.ControlTower.open_landing_strip(name)] end)

    #   Start the dist supervisor on our CT node only
    # Task.Supervisor.start_link name: DistSupervisor

    # Return the supervisor result
    return_sup
  end

  def stop(_) do
    :ok
  end
end
