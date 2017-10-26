defmodule AirElixir.Plane do
  use GenStateMachine, callback_mode: :state_functions

  alias AirElixir.ControlTower

  def start(controltower) do
    plane = create_plane(controltower)
    GenStateMachine.start(__MODULE__, {:in_air, plane})
  end

  def start_link(controltower) do
    plane = create_plane(controltower)
    GenStateMachine.start_link(__MODULE__, {:in_air, plane})
  end

  def permission_to_land(plane), do: GenStateMachine.call(plane, :permission_to_land)

  def land(plane), do: GenStateMachine.cast(plane, :land)

  def rest(plane), do: GenStateMachine.cast(plane, :shutdown)

  def get_state(plane), do: GenStateMachine.call(plane, :get_state)

  ###### State Machine  => status x event ######
  def in_air({:call, from}, :permission_to_land, %{control_tower_pid: ct, flight_number: flight_number} = plane) do
      result = ControlTower.permission_to_land(ct, plane)

      IO.puts("[PLANE] Plane #{flight_number} asks tower #{inspect ct} for permission to land. Got response #{inspect result}")
      case result do
          :cannot_land ->
              IO.puts("[PLANE] Can't land #{inspect plane}")
              {:next_state, :in_air, plane, {:reply, from, :cannot_land}}
          landingstrip ->
              plane1 = %{plane | landing_strip: landingstrip}
              IO.puts("[PLANE] Got permission to land #{inspect plane1}")
              {:next_state, :prepare_for_landing, plane1, {:reply, from, :got_permission}}
      end
  end
  def in_air(event_type, event_content, data) do
    handle_event(event_type, event_content, :in_air, data)
  end

  def prepare_for_landing(:cast, :land, %{control_tower_pid: ct, landing_strip: ls} = plane) do
    ControlTower.land_plane(ct, plane, ls)
    {:next_state, :landed, plane}
  end

  def prepare_for_landing(event_type, event_content, data) do
    handle_event(event_type, event_content, :prepare_for_landing, data)
  end

  def landed(event_type, event_content, data) do
    handle_event(event_type, event_content, :landed, data)
  end

  ## Handle_event callbacks
  def handle_event({:call, from}, :get_state, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end
  def handle_event({:call, from}, event, _state, data) do
    IO.puts("Plane receives an unknown global event: #{event}")
    {:keep_state_and_data, [{:reply, from, data}]}
  end

  def handle_event(:cast, :shutdown, :landed, data) do
    {:stop, :normal, data}
  end

  def terminate(:normal, :landed, plane) do
    IO.puts("[PLANE] #{inspect plane} Finished up shift, chilling out in the hangar.")
    :ok
  end
  def terminate(_reason, _statename, _statedata), do: :ok

  defp generate_flight_number() do
      code = ["IE", "FR", "AF", "BA", "WZ", "BG", "MA", "AB", "DT", "SW", "MM", "FK"]
              |> Enum.random
      num = Integer.to_string(:rand.uniform(1000))
      code <> num
  end

  defp create_plane(controltowerpid) do
      flightnumber = generate_flight_number()
      %{flight_number: flightnumber, control_tower_pid: controltowerpid, landing_strip: nil}
  end
end
