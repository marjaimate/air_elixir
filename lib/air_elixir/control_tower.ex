defmodule AirElixir.ControlTower do
  use GenServer

  alias AirElixir.Plane

  def start_link() do
    start_link(AirElixir.GenAirport)
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def start_link(_, name) do
    start_link(name)
  end

  def open_landing_strip(pid) do
    GenServer.call(pid, :open_landing_strip)
  end

  def status(pid) do
    GenServer.call(pid, :status)
  end

  def close_landing_strip(pid, landing_strip) do
    GenServer.cast(pid, {:close_landing_strip, landing_strip})
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
  def init([]), do: {:ok, %{}}

  def handle_info(msg, landing_strips) do
    IO.puts "[TOWER][#{tower_name(self())}] Unexpected message: #{inspect msg}"
    {:noreply, landing_strips}
  end

  def handle_cast({:close_landing_strip, %{:id => id} = _ls}, landing_strips) do
    can_close_landing_strip(landing_strips[id])
  end

  def handle_cast({:make_landing, %{:flight_number => flight_number}, %{:id => ls_id} = ls, {plane, _} = _from}, landingstrips) do
    IO.puts("[TOWER][#{tower_name(self())}] Plane #{flight_number} landed, freeing up runway #{ls_id}")
    ls_freed = %{ls | free: true}

    Plane.rest(plane)

    {:noreply, Map.put(landingstrips, ls_id, ls_freed)}
  end

  def handle_call(:status, _From, landingstrips) do
    {:reply, landingstrips, landingstrips}
  end

  def handle_call(:open_landing_strip, _From, landingstrips) do
    {id, newls} = create_landing_strip()
    IO.puts("[TOWER][#{tower_name(self())}] Opening new landing strip #{id}")
    {:reply, newls, Map.put(landingstrips, id, newls)}
  end

  def handle_call({:land_plane, %{:flight_number => flight_number} = plane, %{:id => id} = ls}, from, landingstrips) do
    IO.puts("[TOWER][#{tower_name(self())}] Plane #{flight_number} approaching runway #{id} ~n")
    GenServer.cast(self(), {:make_landing, plane, ls, from})
    {:reply, :ok, landingstrips}
  end

  def handle_call({:permission_to_land, plane}, _from, landingstrips) do
    freelsmap = Map.values(landingstrips)
               |> Enum.filter(fn(ls) -> ls[:free] == true end)

    case freelsmap do
      [] ->
        IO.puts("[TOWER][#{tower_name(self())}] Plane #{inspect plane} asked for landing - Landing strip occupied")
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

  def terminate(:normal, landingstrips) do
    IO.puts("[TOWER][#{tower_name(self())}] Landing Strips #{inspect landingstrips} were freed up")
    :ok
  end

  def code_change(_oldvsn, state, _extra) do
    {:ok, state}
  end

  defp create_landing_strip() do
    id = :random.uniform(1000000)
    {id, %{id: id, free: true} }
  end

  defp can_close_landing_strip(nil) do
    IO.puts("[TOWER][#{tower_name(self())}] Landing strip not found")
    {:noreply, %{}}
  end

  defp can_close_landing_strip(%{free: false} = landing_strip) do
    IO.puts("[TOWER][#{tower_name(self())}] Landing strip #{inspect landing_strip} occupied, reschedule close")
    GenServer.cast(self(), {:close_landing_strip, landing_strip})
    {:noreply, landing_strip}
  end

  defp can_close_landing_strip(%{free: true} = landing_strip) do
    IO.puts("[TOWER][#{tower_name(self())}] Closing landing strip #{landing_strip}")
    {:noreply, %{}}
  end

  defp tower_name(pid) do
    :proplists.get_value(:registered_name, Process.info(pid))
  end
end
