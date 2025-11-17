defmodule MsiyspWeb.ActivitiesLive do
  use MsiyspWeb, :live_view
  alias Msiysp.{Repo, Activity, Format}
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    activities = Repo.all(from(a in Activity, where: a.type == "Run", order_by: [desc: a.date]))

    {:ok, assign(socket, activities: activities, filter_type: "Run")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>All Activities</h1>
      <p>Showing <%= length(@activities) %> runs</p>

      <.table id="all-activities" rows={@activities}>
        <:col :let={activity} label="Date">
          <%= Calendar.strftime(activity.date, "%Y-%m-%d %H:%M") %>
        </:col>
        <:col :let={activity} label="Name">
          <%= activity.name %>
        </:col>
        <:col :let={activity} label="Type">
          <%= activity.type %>
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
