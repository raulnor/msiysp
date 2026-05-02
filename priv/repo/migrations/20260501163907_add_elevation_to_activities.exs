defmodule Msiysp.Repo.Migrations.AddElevationToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :elevation_meters, :float
    end
  end
end
