defmodule Msiysp.Repo.Migrations.CreateActivitiesTable do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :date, :date
      add :type, :string
      add :distance_meters, :float
      add :duration_seconds, :float
      add :name, :string
      add :strava_athlete_id, :integer
      add :strava_activity_id, :integer
    end

    create unique_index(:activities, [:strava_activity_id])
  end
end
