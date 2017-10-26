defmodule AirElixir do
  use Application

  def start(:normal, args) do
    start_control_tower(args)
  end

  def start({:takeover, other_node}, args) do
    IO.puts "[SYS] Took over from #{inspect other_node}"
    start_control_tower(args)
  end

  def stop(_) do
    :ok
  end

  defp start_control_tower(args) do
    return_sup = AirElixir.TowerSupervisor.start_link(args)
    airports = Application.get_env(:air_elixir, :airports)

    # Add airports
    airports
    |> List.foldl([], fn({name, _}, acc) -> acc ++ [AirElixir.TowerSupervisor.start_control_tower(name)] end)

    airports
    |> List.foldl([], fn({name, landing_strips}, acc) -> acc ++ open_landing_strips(name, landing_strips) end)

    #   Start the dist supervisor on our CT node only
    # Task.Supervisor.start_link name: DistSupervisor

    # Return the supervisor result
    return_sup
  end

  defp open_landing_strips(airport, n), do: open_landing_strips(airport, n, [])

  defp open_landing_strips(_airport, 0, acc), do: acc
  defp open_landing_strips(airport, n, acc) do
    open_landing_strips(airport, n-1, acc ++ [AirElixir.ControlTower.open_landing_strip(airport)])
  end
end
