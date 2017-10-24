defmodule AirElixir do
  use Application

  def start(_type, args) do
    return_sup = AirElixir.TowerSupervisor.start_link(args)
    # Add airports
    [:budapest, :dublin, :vilnius]
    |> List.foldl([], fn(name, acc) -> acc ++ [AirElixir.TowerSupervisor.start_control_tower(name)] end)

    # Return the supervisor result
    return_sup
  end

  def stop(_) do
    :ok
  end
end
