defmodule AirElixir.ControlTower do
  use GenServer

  alias AirElixir.Plane

  def start_link(), do: start_link(AirElixir.GenAirport)

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end

  def start_link(_, name), do: start_link(name)

  def open_landing_strip(airport) do
    GenServer.call(airport_or_pid(airport), :open_landing_strip)
  end

  def status(airport) do
    GenServer.call(airport_or_pid(airport), :status)
  end

  def close_landing_strip(airport, landing_strip) do
    GenServer.cast(airport_or_pid(airport), {:close_landing_strip, landing_strip})
  end

  def close_airport(airport) do
    GenServer.call(airport_or_pid(airport), :terminate)
  end

  def permission_to_land(airport, plane) do
    GenServer.call(airport_or_pid(airport), {:permission_to_land, plane})
  end

  def land_plane(airport, plane, landing_strip) do
    GenServer.call(airport_or_pid(airport), {:land_plane, plane, landing_strip})
  end

  ##### Gen server callbacks #####
  def init(airport), do: {:ok, %{:airport => airport}}

  def handle_info(msg, %{:airport => airport} = landing_strips) do
    IO.puts "[TOWER][#{airport}] Unexpected message: #{inspect msg}"
    {:noreply, landing_strips}
  end

  def handle_cast({:close_landing_strip, %{:id => id} = _ls}, %{:airport => airport} = landing_strips) do
    can_close_landing_strip(airport, landing_strips[id], landing_strips)
  end
  def handle_cast({:close_landing_strip, id}, %{:airport => airport} = landing_strips) when is_integer(id) do
    can_close_landing_strip(airport, landing_strips[id], landing_strips)
  end

  def handle_cast({:make_landing, %{:flight_number => flight_number}, %{:id => ls_id} = ls, {plane, _} = _from}, %{:airport => airport} = landingstrips) do
    :timer.sleep(300)
    IO.puts("[TOWER][#{airport}] Plane #{flight_number} landed, freeing up runway #{ls_id}")
    ls_freed = %{ls | free: true}

    Plane.rest(plane)

    {:noreply, Map.put(landingstrips, ls_id, ls_freed)}
  end

  def handle_call(:status, _From, landingstrips) do
    {:reply, landingstrips, landingstrips}
  end

  def handle_call(:open_landing_strip, _From, %{:airport => airport} = landingstrips) do
    {id, newls} = create_landing_strip()
    IO.puts("[TOWER][#{airport}] Opening new landing strip #{id}")
    {:reply, newls, Map.put(landingstrips, id, newls)}
  end

  def handle_call({:land_plane, %{:flight_number => flight_number} = plane, %{:id => id} = ls}, from, %{:airport => airport} = landingstrips) do
    IO.puts("[TOWER][#{airport}] Plane #{flight_number} approaching runway #{id} ~n")
    GenServer.cast(self(), {:make_landing, plane, ls, from})
    {:reply, :ok, landingstrips}
  end

  def handle_call({:permission_to_land, plane}, _from, %{:airport => airport} = landingstrips) do
    freelsmap = Map.values(landingstrips)
                |> Enum.filter(&(is_map(&1))) # Filter out the airport name, which is not a map
                |> Enum.filter(fn(ls) -> ls[:free] == true end)

    case freelsmap do
      [] ->
        IO.puts("[TOWER][#{airport}] Plane #{inspect plane} asked for landing - Landing strip occupied")
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

  def terminate(:normal, %{:airport => airport} = landingstrips) do
    IO.puts("[TOWER][#{airport}] Landing Strips #{inspect landingstrips} were freed up")
    :ok
  end

  def code_change(_oldvsn, state, _extra) do
    {:ok, state}
  end

  defp create_landing_strip() do
    id = :rand.uniform(1000000)
    {id, %{id: id, free: true} }
  end

  defp can_close_landing_strip(airport, nil, state) do
    IO.puts("[TOWER][#{airport}] Landing strip not found")
    {:noreply, state}
  end

  defp can_close_landing_strip(airport, %{free: false} = landing_strip, state) do
    IO.puts("[TOWER][#{airport}] Landing strip #{inspect landing_strip} occupied, reschedule close")
    GenServer.cast(self(), {:close_landing_strip, landing_strip})
    {:noreply, state}
  end

  defp can_close_landing_strip(airport, %{free: true, id: id} = landing_strip, state) do
    IO.puts("[TOWER][#{airport}] Closing landing strip #{inspect landing_strip}")
    {:noreply, Map.drop(state, [id])}
  end

  defp airport_or_pid(term) when is_pid(term), do: term
  defp airport_or_pid(term) when is_atom(term), do: {:global, term}
end
