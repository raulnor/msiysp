defmodule MsiyspWeb.ActivitiesLive do
  use MsiyspWeb, :live_view
  alias Msiysp.Format

  @impl true
  def mount(%{"year" => year}, _session, socket) when is_binary(year) do
    {:ok, fetch_data_for_socket(socket, year)}
  end

  def mount(_params, _session, socket) do
    {:ok, fetch_data_for_socket(socket, nil)}
  end

  def fetch_data_for_socket(socket, selected_year) do
    activities =
      case selected_year do
        nil -> Msiysp.ActivityTable.get_activities()
        year -> Msiysp.ActivityTable.get_activities_by_year(year)
      end

    years = Msiysp.ActivityTable.get_activity_years()

    assign(socket,
      activities: activities,
      selected_year: selected_year,
      available_years: years
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>All Activities</h1>
      <div>
        <%= if @selected_year == nil do %>
          <b>All</b>
        <% else %>
          <a href="/activities">All</a>
        <% end %>
        <%= for year <- @available_years do %>
          |
          <%= if @selected_year == year do %>
            <b><%= year %></b>
          <% else %>
            <a href={"/activities/?year=#{year}"}><%= year %></a>
          <% end %>
        <% end %>
      </div>
      <p>Showing <%= length(@activities) %> runs</p>

      <.table id="all-activities" rows={@activities}>
        <:col :let={activity} label="Date">
          <%= Calendar.strftime(activity.date, "%Y-%m-%d %H:%M") %>
        </:col>
        <:col :let={activity} label="Name">
          <%= activity.name %>
        </:col>
        <:col :let={activity} label="Type">
          <%= activity.type %><%= if activity.strava_workout_type == 1, do: " (Race)", else: "" %>
        </:col>
        <:col :let={activity} label="Distance">
          <%= if activity.distance_meters, do: "#{Float.round(activity.distance_meters / 1609.34, 2)} mi", else: "N/A" %>
        </:col>
        <:col :let={activity} label="Duration">
          <%= Format.time(activity.duration_seconds) %>
        </:col>
        <:col :let={activity} label="Pace">
          <%= if activity.distance_meters && activity.distance_meters > 0 do %>
            <%= Format.time(activity.duration_seconds / (activity.distance_meters / 1609.34)) %>
          <% else %>
            N/A
          <% end %>
        </:col>
      </.table>
    </div>
    """
  end
end
