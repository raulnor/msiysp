defmodule Msiysp.ActivityTable do
  import Ecto.Query
  alias Msiysp.Repo
  alias Msiysp.Activity

  def get_activities do
    Repo.all(from(a in Activity, where: a.type == "Run", order_by: [desc: a.date]))
  end

  def get_activities_by_year(year) when is_binary(year) do
    get_activities_by_year(String.to_integer(year))
  end

  def get_activities_by_year(year) do
    start_date = DateTime.new!(Date.new!(year, 1, 1), ~T[00:00:00], "Etc/UTC")
    end_date = DateTime.new!(Date.new!(year, 12, 31), ~T[23:59:59], "Etc/UTC")

    Repo.all(
      from(a in Activity,
        where: a.type == "Run" and a.date >= ^start_date and a.date <= ^end_date,
        order_by: [desc: a.date]
      )
    )
  end

  def get_activity_years() do
    Repo.all(
      from(a in Activity,
        where: a.type == "Run",
        select: fragment("strftime('%Y', ?)", a.date),
        distinct: true,
        order_by: [desc: fragment("strftime('%Y', ?)", a.date)]
      )
    )
  end
end
