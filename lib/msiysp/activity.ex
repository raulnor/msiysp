defmodule Msiysp.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field(:date, :utc_datetime)
    field(:type, :string)
    field(:distance_meters, :float)
    field(:duration_seconds, :float)
    field(:name, :string)
    field(:strava_athlete_id, :integer)
    field(:strava_activity_id, :integer)
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [
      :date,
      :type,
      :distance_meters,
      :duration_seconds,
      :name,
      :strava_athlete_id,
      :strava_activity_id
    ])
    |> validate_required([:date, :type, :strava_activity_id])
    |> unique_constraint(:strava_activity_id)
    |> validate_number(:distance_meters, greater_than_or_equal_to: 0)
    |> validate_number(:duration_seconds, greater_than: 0)
  end

  def changeset_from_strava(activity) do
    {:ok, date, 0} = DateTime.from_iso8601(activity["start_date"])

    %Msiysp.Activity{}
    |> changeset(%{
      date: date,
      type: activity["type"],
      distance_meters: activity["distance"],
      duration_seconds: activity["elapsed_time"],
      name: activity["name"],
      strava_activity_id: activity["id"],
      strava_athlete_id: activity["athlete"]["id"]
    })
  end
end
