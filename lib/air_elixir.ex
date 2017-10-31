defmodule AirElixir do
  use Application

  def start(_type, args) do
    return_sup = AirElixir.TowerSupervisor.start_link(args)
    airports = Application.get_env(:air_elixir, :airports)
    output_function = get_output_function(Application.get_env(:air_elixir, :output_function))

    # Add airports
    airports
    |> List.foldl([], fn({name, number_of_landing_strips}, acc) -> acc ++ [AirElixir.TowerSupervisor.start_control_tower(name, number_of_landing_strips)] end)
    |> List.foldl([], fn({:ok, pid}, acc) -> [AirElixir.ControlTower.set_output(pid, output_function) | acc] end)

    #   Start the dist supervisor on our CT node only
    # Task.Supervisor.start_link name: DistSupervisor

    # Return the supervisor result
    return_sup
  end

  def stop(_) do
    :ok
  end

  def get_output_function(nil), do: &IO.puts/1
  def get_output_function(f), do: f
end
