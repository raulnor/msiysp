defmodule Msiysp.Repo.Migrations.AddWorkoutTypeToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :strava_workout_type, :integer
    end
  end
end
