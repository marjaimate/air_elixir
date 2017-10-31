defmodule AirElixir.ControlTower do
  use GenServer

  alias AirElixir.Plane

  def start_link() do
    start_link(AirElixir.GenAirport, 1)
  end

  def start_link(name, number_of_landing_strips) do
    GenServer.start_link(__MODULE__, [name, number_of_landing_strips], name: name)
  end

  def start_link(_, name, number_of_landing_strips) do
    start_link(name, number_of_landing_strips)
  end

  def status(pid) do
    GenServer.call(pid, :status)
  end

  def set_output(pid, output_fn) do
    GenServer.call(pid, {:set_output, output_fn})
  end

  def close_airport(pid) do
    GenServer.call(pid, :terminate)
  end

  def permission_to_land(pid, plane) do
    GenServer.call(pid, {:permission_to_land, plane})
  end

  def land_plane(pid, plane, landing_strip) do
    GenServer.call(pid, {:land_plane, plane, landing_strip})
  end

  ##### Gen server callbacks #####
  def init([airport, number_of_landing_strips]) do
    state = create_landing_strips(number_of_landing_strips)
         |> List.foldl(%{airport: airport, output: &IO.puts/1}, fn {id, ls}, acc -> Map.put(acc, id, ls) end)

    {:ok, state}
  end

  def handle_info(msg, %{output: output} = landing_strips) do
    output.("[TOWER][#{tower_name(self())}] Unexpected message: #{inspect msg}")
    {:noreply, landing_strips}
  end

  def handle_cast({:make_landing, %{:flight_number => flight_number}, %{:id => ls_id} = ls, {plane, _} = _from}, %{output: output} = landingstrips) do
    :timer.sleep(300)
    output.("[TOWER][#{tower_name(self())}] Plane #{flight_number} landed, freeing up runway #{ls_id}")
    ls_freed = %{ls | free: true}

    Plane.rest(plane)

    {:noreply, Map.put(landingstrips, ls_id, ls_freed)}
  end

  def handle_call({:set_output, output}, _From, landingstrips) do
    ls = Map.put landingstrips, :output, output
    {:reply, ls, ls}
  end

  def handle_call(:status, _From, landingstrips) do
    {:reply, landingstrips, landingstrips}
  end

  def handle_call({:land_plane, %{:flight_number => flight_number} = plane, %{:id => id} = ls}, from, %{output: output} = landingstrips) do
    output.("[TOWER][#{tower_name(self())}] Plane #{flight_number} approaching runway #{id} ~n")
    GenServer.cast(self(), {:make_landing, plane, ls, from})
    {:reply, :ok, landingstrips}
  end

  def handle_call({:permission_to_land, plane}, _from, %{output: output} = landingstrips) do
    freelsmap = Map.values(landingstrips)
                |> Enum.filter(&(is_map(&1))) # Filter out the airport name, which is not a map
                |> Enum.filter(fn(ls) -> ls[:free] == true end)

    case freelsmap do
      [] ->
        output.("[TOWER][#{tower_name(self())}] Plane #{inspect plane} asked for landing - Landing strip occupied")
        {:reply, :cannot_land, landingstrips}
      [ls_chosen | _] ->
        landingstripoccupied = %{ls_chosen | free: false}
        newlandingstrips = %{landingstrips | ls_chosen[:id] => landingstripoccupied}
        {:reply, landingstripoccupied, newlandingstrips}
    end
  end

  def handle_call(:terminate, _from, landingstrips) do
    {:stop, :normal, :ok, landingstrips}
  end

  def terminate(:normal, %{output: output} = landingstrips) do
    output.("[TOWER][#{tower_name(self())}] Landing Strips #{inspect landingstrips} were freed up")
    :ok
  end

  defp create_landing_strips(n), do: create_landing_strips(n, [])

  defp create_landing_strips(0, acc), do: acc
  defp create_landing_strips(n, acc), do: create_landing_strips(n-1, [create_landing_strip() | acc])

  defp create_landing_strip() do
    id = :rand.uniform(1000000)
    {id, %{id: id, free: true} }
  end

  defp tower_name(pid) do
    :proplists.get_value(:registered_name, Process.info(pid))
  end
end
