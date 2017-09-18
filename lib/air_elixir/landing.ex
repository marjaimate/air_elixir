defmodule AirElixir.Landing do
  alias AirElixir.ControlTower
  alias AirElixir.Plane

  def test_single_plane() do
    {:ok, ct} = ControlTower.start_link()
    ls1 = ControlTower.open_landing_strip(ct)
    plane = get_plane(ct)

    IO.puts("Control Tower: #{inspect ct} | Landing Strip: #{inspect ls1}")
    IO.puts("~n -- plane: #{inspect plane}")

    Plane.permission_to_land(plane)
    Plane.land(plane)

    :timer.sleep(1000)
    ControlTower.close_airport(ct)
    :ok
  end

  def get_plane(ct) do
    {:ok, pid} = Plane.start(ct)
    pid
  end
end
