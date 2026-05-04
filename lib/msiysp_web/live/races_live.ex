defmodule MsiyspWeb.RacesLive do
  use MsiyspWeb, :live_view
  import Ecto.Query
  alias Msiysp.{Repo, Activity, Format}

  @meters_per_mile 1609.34

  @impl true
  def mount(_params, _session, socket) do
    {:ok, fetch_data(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 style="margin-bottom: 20px;">Races</h1>

      <div class="stats">
        <div class="stat-card">
          <div class="stat-value"><%= @total_races %></div>
          <div class="stat-label">Total Races</div>
        </div>
        <div class="stat-card">
          <div class="stat-value"><%= @best_pace %></div>
          <div class="stat-label">Best Pace (min/mi)</div>
        </div>
        <div class="stat-card">
          <div class="stat-value"><%= @longest_distance %></div>
          <div class="stat-label">Longest Race</div>
        </div>
      </div>

      <.table id="races" rows={@races}>
        <:col :let={r} label="Date">
          <%= Calendar.strftime(r.date, "%Y-%m-%d") %>
        </:col>
        <:col :let={r} label="Name">
          <%= r.name %>
        </:col>
        <:col :let={r} label="Distance">
          <%= Float.round(r.distance_meters / 1609.34, 2) %> mi
        </:col>
        <:col :let={r} label="Time">
          <%= Format.time(r.duration_seconds) %>
        </:col>
        <:col :let={r} label="Pace">
          <%= Format.time(r.duration_seconds / (r.distance_meters / 1609.34)) %>/mi
        </:col>
        <:col :let={r}>
          <a href={"https://www.strava.com/activities/#{r.strava_activity_id}"} target="_blank">Strava</a>
        </:col>
      </.table>
    </div>
    """
  end

  defp fetch_data(socket) do
    races =
      Repo.all(
        from(a in Activity,
          where: a.type == "Run" and a.strava_workout_type == 1,
          order_by: [desc: a.date]
        )
      )

    best_pace =
      races
      |> Enum.filter(&(&1.distance_meters > 0))
      |> Enum.min_by(&(&1.duration_seconds / (&1.distance_meters / @meters_per_mile)), fn ->
        nil
      end)
      |> case do
        nil -> "—"
        r -> Format.time(r.duration_seconds / (r.distance_meters / @meters_per_mile))
      end

    longest =
      races
      |> Enum.max_by(& &1.distance_meters, fn -> nil end)
      |> case do
        nil -> "—"
        r -> "#{Float.round(r.distance_meters / @meters_per_mile, 1)} mi"
      end

    assign(socket,
      races: races,
      total_races: length(races),
      best_pace: best_pace,
      longest_distance: longest
    )
  end
end
