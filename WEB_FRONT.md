# Create a new Phoenix application

```bash
$ mix phx.new air_traffic
```

# Add AirElixir as a dependency

```elixir
# mix.exs

#### snip ####

  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:air_elixir, git: "git@github.com:marjaimate/air_elixir.git", branch: "master"}
    ]
  end

#### snip ####
```

```bash
$ mix deps.get
```

# Add your airport configuration

```elixir
# config/config.exs


config :air_elixir,
  airports: [
    {:budapest, 2},
    {:dublin, 4},
    {:vilnius, 1},
    {:london, 7},
    {:rome, 3},
    {:berlin, 4},
    {:barcelona, 6}
  ]
```

# Run the server and see AirElixir starting up

```bash
$ mix phx.server
```

# Now, start adding some controllers and views

## List airports

```elixir
# lib/air_traffic_web/controllers/airports_controller.ex
defmodule AirTrafficWeb.AirportsController do
  use AirTrafficWeb, :controller

  alias AirElixir.ControlTower
  alias AirElixir.TowerSupervisor
  alias AirElixir.Plane

  def index(conn, _params) do
    conn
    |> assign(:airports, get_airports())
    |> render("index.html")
  end

  def open_new(conn, %{"airport" => name, "landing_strips" => landing_strips} = params) do
    airport = String.to_atom(name)
    TowerSupervisor.start_control_tower(airport)
    open_landing_strips(airport, String.to_integer(landing_strips))

    conn |> redirect(to: "/airports")
  end

  ### Private ###
  defp get_airports do
    Supervisor.which_children(TowerSupervisor)
      |> Enum.map(fn {_, pid, _, _ } -> pid end)
      |> Enum.map(&( { :proplists.get_value(:registered_name, Process.info(&1)), ControlTower.status(&1) } ))
  end


  defp open_landing_strips(airport, n), do: open_landing_strips(airport, n, [])

  defp open_landing_strips(_airport, 0, acc), do: acc
  defp open_landing_strips(airport, n, acc) do
    open_landing_strips(airport, n-1, acc ++ [ControlTower.open_landing_strip(airport)])
  end
end
```

```elixir
# lib/air_traffic_web/views/airports_view.ex

defmodule AirTrafficWeb.AirportsView do
  use AirTrafficWeb, :view

  def get_csrf_token(_conn) do
    Plug.CSRFProtection.get_csrf_token()
  end
end
```

```elixir
# lib/templates/airports/index.html.eex

<div class="jumbotron">
  <h2>Airports status report</h2>
    <hr/>
  <%= for {airport, status} <- @airports do %>
    <b><%= airport %></b>:
    <br>
    <%= inspect status %>

    <hr/>
  <% end %>
  <form method="POST" action="/airports">
    <input name="_csrf_token" value="<%= get_csrf_token(@conn) %>" type="hidden">
    <div class="form-group">
      <label>Airport Name</label>
      <input type="text" name="airport" id="airport" class="form-control">
    </div>

    <div class="form-group">
      <label>Number of Landing Strips</label>
      <input type="number" name="landing_strips" id="landing_strips" class="form-control">
    </div>

    <div class="form-group">
      <%= submit "Create Airport", class: "btn btn-primary" %>
    </div>
  </form>
</div>
```

```elixir
# lib/router.ex
defmodule AirTrafficWeb.Router do
  use AirTrafficWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AirTrafficWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/airports", AirportsController, :index
    post "/airports", AirportsController, :open_new
  end
end
```

# Send some planes to the airports

```elixir
# lib/air_traffic_web/controllers/airports_controller.ex

  def send_planes(conn, %{"number_of_planes" => number_of_planes} = _params) do
    airports = get_airports() |> Enum.map(fn {n, _} -> n end)

    1..(String.to_integer(number_of_planes))
      |> Enum.map(fn _ -> Plane.start_link(Enum.random(airports)) end)
      |> Enum.map(fn {:ok, pid} -> pid end)
      |> land_planes

    conn
    |> assign(:airports, get_airports())
    |> render("index.html")
  end

  ## Land planes
  defp land_planes([]), do: :ok
  defp land_planes([plane | rest]) do
    permission = Plane.permission_to_land(plane)
    planes = attempt_to_land_plane(permission, plane, rest)
    land_planes(planes)
  end

  # IF we got the go ahead -> land the plane and carry on with the rest of the planes
  defp attempt_to_land_plane(:got_permission, plane, rest) do
    Plane.land(plane)
    rest
  end
  # IF we can't land -> put the plane at the back of the queue
  defp attempt_to_land_plane(:cannot_land, plane, rest) do
    rest ++ [plane]
  end
```

```elixir
# lib/router.ex

    post "/send_planes", AirportsController, :send_planes

```


``` elixir
# lib/templates/airports/index.html.eex

  <hr/>
  <form method="POST" action="/send_planes">
    <input name="_csrf_token" value="<%= get_csrf_token(@conn) %>" type="hidden">

    <div class="form-group">
      <label>Number of Planes</label>
      <input type="number" name="number_of_planes" id="number_of_planes" class="form-control">
    </div>

    <div class="form-group">
      <%= submit "Send Planes", class: "btn btn-primary" %>
    </div>
  </form>
```
