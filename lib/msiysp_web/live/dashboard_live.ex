defmodule MsiyspWeb.DashboardLive do
  use MsiyspWeb, :live_view
  alias Msiysp.{Repo, Activity, Format}
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    activities = Repo.all(from(a in Activity, where: a.type == "Run", order_by: [desc: a.date]))

    total_runs = length(activities)
    total_distance = activities |> Enum.map(& &1.distance_meters) |> Enum.sum()
    total_time = activities |> Enum.map(& &1.duration_seconds) |> Enum.sum()

    avg_distance = if total_runs > 0, do: total_distance / total_runs, else: 0
    avg_pace = if total_distance > 0, do: total_time / (total_distance / 1609.34), else: 0

    recent_activities = Enum.take(activities, 10)

    {:ok,
     assign(socket,
       total_runs: total_runs,
       total_distance_miles: total_distance / 1609.34,
       total_time_hours: total_time / 3600,
       avg_distance_miles: avg_distance / 1609.34,
       avg_pace: avg_pace,
       recent_activities: recent_activities
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Running Dashboard</h1>

      <div class="stats">
        <div class="stat-card">
          <div class="stat-value"><%= @total_runs %></div>
          <div class="stat-label">Total Runs</div>
        </div>

        <div class="stat-card">
          <div class="stat-value"><%= Float.round(@total_distance_miles, 1) %></div>
          <div class="stat-label">Total Miles</div>
        </div>

        <div class="stat-card">
          <div class="stat-value"><%= Float.round(@total_time_hours, 1) %></div>
          <div class="stat-label">Total Hours</div>
        </div>

        <div class="stat-card">
          <div class="stat-value"><%= Float.round(@avg_distance_miles, 2) %></div>
          <div class="stat-label">Avg Distance (miles)</div>
        </div>

        <div class="stat-card">
          <div class="stat-value"><%= Format.time(@avg_pace) %></div>
          <div class="stat-label">Avg Pace (min/mile)</div>
        </div>
      </div>

      <h2>Recent Activities</h2>
      <.table id="recent-activities" rows={@recent_activities}>
        <:col :let={activity} label="Date">
          <%= Calendar.strftime(activity.date, "%Y-%m-%d") %>
        </:col>
        <:col :let={activity} label="Name">
          <%= activity.name %>
        </:col>
        <:col :let={activity} label="Type">
          <%= activity.type %><%= if activity.strava_workout_type == 1, do: " (Race)", else: "" %>
        </:col>
        <:col :let={activity} label="Distance">
          <%= Float.round(activity.distance_meters / 1609.34, 2) %> mi
        </:col>
        <:col :let={activity} label="Duration">
          <%= Format.time(activity.duration_seconds) %>
        </:col>
        <:col :let={activity} label="Pace">
          <%= Format.time(activity.duration_seconds / (activity.distance_meters / 1609.34)) %>
        </:col>
        <:col :let={activity}>
          <a href={"https://www.strava.com/activities/#{activity.strava_activity_id}/edit"}>Edit</a>
        </:col>
      </.table>
    </div>
    """
  end
end
