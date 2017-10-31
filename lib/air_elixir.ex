defmodule AirElixir do
  use Application

  def start(_type, args) do
    return_sup = AirElixir.TowerSupervisor.start_link(args)
    airports = Application.get_env(:air_elixir, :airports)

    # Add airports
    airports
    |> List.foldl([], fn({name, number_of_landing_strips}, acc) -> acc ++ [AirElixir.TowerSupervisor.start_control_tower(name, number_of_landing_strips)] end)

    #   Start the dist supervisor on our CT node only
    # Task.Supervisor.start_link name: DistSupervisor

    # Return the supervisor result
    return_sup
  end

  def stop(_) do
    :ok
  end
end
