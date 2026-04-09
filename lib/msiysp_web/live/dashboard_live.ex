defmodule MsiyspWeb.DashboardLive do
  use MsiyspWeb, :live_view
  alias Msiysp.{Repo, Activity, Format}
  import Ecto.Query

  @impl true
  def mount(%{"year" => year}, _session, socket) when is_binary(year) do
    {:ok, fetch_data_for_socket(socket, year)}
  end

  def mount(_params, _session, socket) do
    {:ok, fetch_data_for_socket(socket, nil)}
  end

  @impl true
  def handle_event("sync_strava", _params, socket) do
    Task.async(fn ->
      Msiysp.Strava.sync_activities()
    end)

    {:noreply, put_flash(socket, :info, "Syncing latest activities from Strava...")}
  end

  @impl true
  def handle_info({ref, _result}, socket) when is_reference(ref) do
    send(self(), :reload_data)
    {:noreply, put_flash(socket, :info, "Load complete! Refresh to view.")}
  end

  @impl true
  def handle_info(:reload_data, socket) do
    params =
      if socket.assigns.selected_year, do: %{"year" => socket.assigns.selected_year}, else: %{}

    socket =
      socket
      |> clear_flash(:info)
      |> fetch_data_for_socket(params)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <div>
          <h1 style="margin: 0 0 10px 0;">Running Dashboard</h1>
          <div>
            <%= if @selected_year == nil do %>
              <b>All</b>
            <% else %>
              <a href="/">All</a>
            <% end %>
            <%= for year <- @available_years do %>
              |
              <%= if @selected_year == year do %>
                <b><%= year %></b>
              <% else %>
                <a href={"/?year=#{year}"}><%= year %></a>
              <% end %>
            <% end %>
          </div>
        </div>
        <button phx-click="sync_strava" class="sync-button">Sync from Strava</button>
      </div>

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

  defp get_activities do
    Repo.all(from(a in Activity, where: a.type == "Run", order_by: [desc: a.date]))
  end

  defp get_activities_by_year(year) when is_binary(year) do
    get_activities_by_year(String.to_integer(year))
  end

  defp get_activities_by_year(year) do
    start_date = DateTime.new!(Date.new!(year, 1, 1), ~T[00:00:00], "Etc/UTC")
    end_date = DateTime.new!(Date.new!(year, 12, 31), ~T[23:59:59], "Etc/UTC")

    Repo.all(
      from(a in Activity,
        where: a.type == "Run" and a.date >= ^start_date and a.date <= ^end_date,
        order_by: [desc: a.date]
      )
    )
  end

  defp fetch_data_for_socket(socket, selected_year) do
    activities =
      case selected_year do
        nil -> get_activities()
        year -> get_activities_by_year(year)
      end

    years =
      Repo.all(
        from(a in Activity,
          where: a.type == "Run",
          select: fragment("strftime('%Y', ?)", a.date),
          distinct: true,
          order_by: [desc: fragment("strftime('%Y', ?)", a.date)]
        )
      )

    total_runs = length(activities)
    total_distance = activities |> Enum.map(& &1.distance_meters) |> Enum.sum()
    total_time = activities |> Enum.map(& &1.duration_seconds) |> Enum.sum()

    avg_distance = if total_runs > 0, do: total_distance / total_runs, else: 0
    avg_pace = if total_distance > 0, do: total_time / (total_distance / 1609.34), else: 0

    recent_activities = Enum.take(activities, 10)

    assign(socket,
      selected_year: selected_year,
      available_years: years,
      total_runs: total_runs,
      total_distance_miles: total_distance / 1609.34,
      total_time_hours: total_time / 3600,
      avg_distance_miles: avg_distance / 1609.34,
      avg_pace: avg_pace,
      recent_activities: recent_activities
    )
  end
end
