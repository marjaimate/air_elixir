defmodule AirElixir.Landing do
  alias AirElixir.ControlTower
  alias AirElixir.Plane

  def test_many_planes_to_airports() do
    airports = Application.get_env(:air_elixir, :airports)
               |> Enum.map(fn {name, _} -> name end)

    1..1000
    |> Enum.map(fn i -> AirElixir.Plane.start_link(Enum.random(airports)) end)
    |> Enum.map(fn {:ok, pid} -> pid end)
    |> land_planes
  end

  def test_single_plane() do
    {:ok, ct} = ControlTower.start_link()
    ls1 = ControlTower.open_landing_strip(ct)
    plane = get_plane(ct)

    land_planes([plane])

    :timer.sleep(1000)
    ControlTower.close_airport(ct)
    :ok
  end

  def get_plane(ct) do
    {:ok, pid} = Plane.start(ct)
    pid
  end

  defp land_planes([]), do: :ok
  defp land_planes([plane | rest]) do
    permission = Plane.permission_to_land(plane)
    planes = attempt_to_land_plane(permission, plane, rest)
    land_planes(planes)
  end

  # IF we got the go ahead -> land the plane and carry on with the rest of the planes
  defp attempt_to_land_plane(:got_permission, plane, rest) do
    AirElixir.Plane.land(plane)
    rest
  end
  # IF we can't land -> put the plane at the back of the queue
  defp attempt_to_land_plane(:cannot_land, plane, rest) do
    rest ++ [plane]
  end
end
