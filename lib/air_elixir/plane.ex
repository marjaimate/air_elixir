defmodule AirElixir.Plane do
  @behaviour :gen_fsm

  alias AirElixir.ControlTower

  def start(controltowerpid) do
    plane = create_plane(controltowerpid)
    :gen_fsm.start(__MODULE__, [plane], [])
  end

  def start_link(controltowerpid) do
    plane = create_plane(controltowerpid)
    :gen_fsm.start_link(__MODULE__, [plane], [])
  end

  def permission_to_land(planepid) do
    :gen_fsm.send_event(planepid, :permission_to_land)
  end

  def land(planepid) do
      :gen_fsm.send_event(planepid, :land)
  end

  def rest(planepid) do
      :gen_fsm.send_all_state_event(planepid, :shutdown)
  end

  def get_state(planepid) do
      :gen_fsm.sync_send_all_state_event(planepid, :get_state)
  end

  ###### fsm ######
  def init([plane]), do: {:ok, :in_air, plane}

  def in_air(:permission_to_land, %{control_tower_pid: ct, flight_number: flight_number} = plane) do
      result = ControlTower.permission_to_land(ct, plane)

      IO.puts("[PLANE] Plane #{flight_number} asks tower #{inspect ct} for permission to land. Got response #{inspect result}")
      case result do
          :cannot_land ->
              IO.puts("[PLANE] Can't land #{inspect plane}")
              {:next_state, :in_air, plane}
          landingstrip ->
              plane1 = %{plane | landing_strip: landingstrip}
              IO.puts("[PLANE] Got permission to land #{inspect plane1}")
              {:next_state, :prepare_for_landing, plane1}
      end
  end

  def in_air(event, data) do
      unexpected(event, :in_air)
      {:next_state, :in_air, data}
  end

  def prepare_for_landing(:land, %{control_tower_pid: ct, landing_strip: ls} = plane) do
      ControlTower.land_plane(ct, plane, ls)
      {:next_state, :landed, plane}
  end

  def terminate(:normal, :landed, plane) do
      IO.puts("[PLANE] #{inspect plane} Finished up shift, chilling out in the hangar.")
      :ok
  end

  def terminate(_reason, _statename, _statedata), do: :ok

  def unexpected(msg, state) do
      IO.puts("#{self()} received unknown event #{msg} while in state #{state}")
  end

  def handle_info(info, state, data) do
      IO.puts("#{self()} received unknown event #{info} while in state #{state}")
      {:next_state, state, data}
  end

  def handle_event(:shutdown, _statename, state) do
      {:stop, :normal, state}
  end
  def handle_event(event, statename, state) do
      IO.puts("Plane receives an unknown global event: #{event}")
      {:next_state, statename, state}
  end

  def handle_sync_event(:get_state, _from, statename, state) do
      { :reply, statename, statename, state }
  end

  def handle_sync_event(event, _from, statename, _state) do
      IO.puts("Plane receives an unknown global sync event: #{event}")
      {:reply, "You are not understood", event, statename}
  end

  def code_change(_oldvsn, statename, data, _extra) do
      {:ok, statename, data}
  end

  defp generate_flight_number() do
      code = ["IE", "FR", "AF", "BA", "WZ", "BG", "MA", "AB", "DT", "SW", "MM", "FK"]
              |> Enum.random
      num = Integer.to_string(:random.uniform(1000))
      code <> num
  end

  defp create_plane(controltowerpid) do
      flightnumber = generate_flight_number()
      %{flight_number: flightnumber, control_tower_pid: controltowerpid, landing_strip: nil}
  end
end
