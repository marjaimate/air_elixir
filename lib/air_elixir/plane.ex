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

  def set_output(plane, output_fn), do: GenStateMachine.call(plane, {:set_output, output_fn})

  ###### State Machine  => status x event ######
  def in_air({:call, from}, :permission_to_land, %{control_tower_pid: ct, flight_number: flight_number, output: output} = plane) do
      result = ControlTower.permission_to_land(ct, plane)

      output.("[PLANE][#{flight_number}] asks tower #{inspect ct} for permission to land. Got response #{inspect result}")
      case result do
          :cannot_land ->
              output.("[PLANE][#{flight_number}] Can't land, circling around the airport")
              {:next_state, :in_air, plane, {:reply, from, :cannot_land}}
          landingstrip ->
              plane1 = %{plane | landing_strip: landingstrip}
              output.("[PLANE][#{flight_number}] Got permission to land")
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
  def handle_event({:call, from}, {:set_output, output}, state, data) do
    new_data = Map.put data, :output, output
    {:next_state, state, new_data, [{:reply, from, new_data}]}
  end
  def handle_event({:call, from}, :get_state, state, _data) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end
  def handle_event({:call, from}, event, _state, %{output: output} = data) do
    output.("Plane receives an unknown global event: #{event}")
    {:keep_state_and_data, [{:reply, from, data}]}
  end

  def handle_event(:cast, :shutdown, :landed, data) do
    {:stop, :normal, data}
  end

  def terminate(:normal, :landed, %{flight_number: flight_number, output: output} = plane) do
    output.("[PLANE][#{flight_number}] Finished up shift, chilling out in the hangar.")
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
      %{output: output} = AirElixir.ControlTower.status(controltowerpid) # Use the same output as the control tower
      %{flight_number: flightnumber, control_tower_pid: controltowerpid, landing_strip: nil, output: output}
  end
end
