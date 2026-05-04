defmodule MsiyspWeb.ProgressLive do
  use MsiyspWeb, :live_view
  import Ecto.Query
  alias Msiysp.{Repo, Activity}

  @meters_per_mile 1609.34

  @impl true
  def mount(%{"start" => "all"}, _session, socket) do
    now = DateTime.utc_now()
    {:ok, fetch_data_for_socket(socket, :all, now)}
  end

  def mount(%{"start" => start_str, "end" => end_str}, _session, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      end_dt = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")
      {:ok, fetch_data_for_socket(socket, start_dt, end_dt)}
    else
      _ -> {:ok, fetch_data_for_socket(socket, default_start(), DateTime.utc_now())}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, fetch_data_for_socket(socket, default_start(), DateTime.utc_now())}
  end

  defp default_start, do: DateTime.add(DateTime.utc_now(), -365, :day)

  @impl true
  def render(assigns) do
    ~H"""
    <script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>
    <script>
      window.renderProgressChart = function(el) {
        const weeks = JSON.parse(el.dataset.weeks)
        const labels = weeks.map(w => w.week)
        const values = weeks.map(w => w.miles)
        const css = getComputedStyle(document.documentElement)
        const accent = css.getPropertyValue("--color-accent").trim()
        const surface = css.getPropertyValue("--color-surface").trim()
        const secondary = css.getPropertyValue("--color-secondary").trim()
        const border = css.getPropertyValue("--color-border").trim()

        const mainTrace = {
          x: labels,
          y: values,
          type: "scatter",
          mode: "lines+markers",
          fill: "tozeroy",
          line: { color: accent, width: 2 },
          fillcolor: "rgba(246,187,85,0.15)",
          marker: { color: surface, size: 8, line: { color: accent, width: 2 } },
          hoverinfo: "none"
        }

        const hoverTrace = {
          x: labels,
          y: values.map(() => 1),
          type: "bar",
          yaxis: "y2",
          marker: { color: "rgba(0,0,0,0)", line: { width: 0 } },
          hoverinfo: "none",
          showlegend: false
        }

        const layout = {
          margin: { t: 10, r: 20, b: 40, l: 55 },
          xaxis: { type: "date", tickformat: "%b", tickfont: { size: 11, color: secondary }, showgrid: false, zeroline: false, showline: false },
          yaxis: { showgrid: true, gridcolor: border, ticksuffix: " mi", tickfont: { size: 11, color: secondary }, rangemode: "tozero", zeroline: false },
          yaxis2: { overlaying: "y", range: [0, 1], showgrid: false, showticklabels: false, zeroline: false },
          bargap: 0,
          plot_bgcolor: surface,
          paper_bgcolor: surface,
          showlegend: false,
          hovermode: "x",
          shapes: []
        }

        const weekLabel = document.getElementById("progress-week-label")
        const distLabel = document.getElementById("progress-distance")
        const timeLabel = document.getElementById("progress-time")
        const elevLabel = document.getElementById("progress-elev")
        const paceLabel = document.getElementById("progress-pace")

        function formatDuration(secs) {
          const h = Math.floor(secs / 3600)
          const m = Math.floor((secs % 3600) / 60)
          return h > 0 ? `${h}h ${m}m` : `${m}m`
        }

        function formatPace(miles, secs) {
          if (!miles || miles === 0) return "—"
          const secsPerMile = secs / miles
          const m = Math.floor(secsPerMile / 60)
          const s = Math.round(secsPerMile % 60).toString().padStart(2, "0")
          return `${m}:${s}/mi`
        }

        function formatElev(meters) {
          const ft = Math.round(meters * 3.28084)
          return ft.toLocaleString("en-US") + " ft"
        }

        function formatDateRange(start, end) {
          const [s_y, s_m, s_d] = start.split("-").map(Number)
          const [e_y, e_m, e_d] = end.split("-").map(Number)
          const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
          if (s_y == e_y) {
            return `${months[s_m-1]} ${s_d} - ${months[e_m-1]} ${e_d}, ${e_y}`
          } else {
            return `${months[s_m-1]} ${s_d}, ${s_y} - ${months[e_m-1]} ${e_d}, ${e_y}`
          }
        }

        const totalMiles = weeks.reduce((s, w) => s + w.miles, 0)
        const totalSecs = weeks.reduce((s, w) => s + w.seconds, 0)
        const totalElevMeters = weeks.reduce((s, w) => s + w.elev_meters, 0)
        const firstWeek = weeks[0]
        const lastWeek = weeks[weeks.length - 1]

        const defaultWeekLabel = formatDateRange(firstWeek.week, lastWeek.week_end)
        const defaultDist = totalMiles.toFixed(2) + " mi"
        const defaultTime = formatDuration(totalSecs)
        const defaultElev = formatElev(totalElevMeters)
        const defaultPace = formatPace(totalMiles, totalSecs)

        function showDefaults() {
          if (weekLabel) weekLabel.textContent = defaultWeekLabel
          if (distLabel) distLabel.textContent = defaultDist
          if (timeLabel) timeLabel.textContent = defaultTime
          if (elevLabel) elevLabel.textContent = defaultElev
          if (paceLabel) paceLabel.textContent = defaultPace
          const header = document.getElementById("progress-header")
          if (header) header.style.visibility = "visible"
        }

        Plotly.react(el, [mainTrace, hoverTrace], layout, { responsive: true, displayModeBar: false })
          .then(() => showDefaults())

        el.on("plotly_hover", function(data) {
          const pt = data.points.find(p => p.pointIndex < weeks.length)
          if (!pt) return
          const idx = pt.pointIndex
          const w = weeks[idx]

          weekLabel.textContent = formatDateRange(w.week, w.week_end)
          distLabel.textContent = w.miles.toFixed(2) + " mi"
          timeLabel.textContent = formatDuration(w.seconds)
          if (elevLabel) elevLabel.textContent = formatElev(w.elev_meters)
          if (paceLabel) paceLabel.textContent = formatPace(w.miles, w.seconds)

          Plotly.relayout(el, {
            shapes: [{ type: "line", x0: w.week, x1: w.week, y0: 0, y1: w.miles, line: { color: secondary, width: 1.5 }, yanchor: "y", layer: "below" }]
          })

        })

        el.on("plotly_unhover", function() {
          showDefaults()
          Plotly.relayout(el, { shapes: [] })
        })
      }
    </script>
    <div>
      <h1 style="margin-bottom: 8px;">Progress</h1>
      <div style="margin-bottom: 20px;">
        <%= for {label, range, url} <- @picker_ranges do %>
          <%= if range != "3m" do %>|<% end %>
          <%= if @selected_range == range do %>
            <b><%= label %></b>
          <% else %>
            <a href={url}><%= label %></a>
          <% end %>
        <% end %>
      </div>

      <div style="background: var(--color-surface); border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.3);">
        <div id="progress-header" style="visibility: hidden;">
          <div style="font-size: 1.1em; font-weight: 700; margin-bottom: 8px; color: var(--color-primary);" id="progress-week-label"></div>
          <div style="display: flex; gap: 40px; margin-bottom: 16px;">
            <div>
              <div style="font-size: 0.85em; color: var(--color-secondary);">Distance</div>
              <div style="font-size: 1.6em; font-weight: 700; color: var(--color-primary);" id="progress-distance"></div>
            </div>
            <div>
              <div style="font-size: 0.85em; color: var(--color-secondary);">Time</div>
              <div style="font-size: 1.6em; font-weight: 700; color: var(--color-primary);" id="progress-time"></div>
            </div>
            <div>
              <div style="font-size: 0.85em; color: var(--color-secondary);">Elev Gain</div>
              <div style="font-size: 1.6em; font-weight: 700; color: var(--color-primary);" id="progress-elev"></div>
            </div>
            <div>
              <div style="font-size: 0.85em; color: var(--color-secondary);">Avg Pace</div>
              <div style="font-size: 1.6em; font-weight: 700; color: var(--color-primary);" id="progress-pace"></div>
            </div>
          </div>
        </div>
        <div
          id="progress-chart"
          phx-hook="PlotlyChart"
          data-weeks={Jason.encode!(@weeks)}
        >
        </div>
      </div>
    </div>
    """
  end

  defp fetch_data_for_socket(socket, start_dt_or_all, end_dt) do
    now = DateTime.utc_now()
    today = DateTime.to_date(now)

    range_starts = %{
      "3m" => DateTime.add(now, -91, :day),
      "ytd" => DateTime.new!(Date.new!(today.year, 1, 1), ~T[00:00:00], "Etc/UTC"),
      "1y" => DateTime.add(now, -365, :day),
      "2y" => DateTime.add(now, -730, :day)
    }

    picker_ranges =
      Enum.map([{"3M", "3m"}, {"YTD", "ytd"}, {"1Y", "1y"}, {"2Y", "2y"}], fn {label, range} ->
        rs = range_starts[range]

        url =
          "/progress?start=#{Date.to_iso8601(DateTime.to_date(rs))}&end=#{Date.to_iso8601(today)}"

        {label, range, url}
      end) ++ [{"All", "all", "/progress?start=all"}]

    {selected_range, activities, actual_start} =
      case start_dt_or_all do
        :all ->
          acts = fetch_all_activities()
          first = acts |> List.first() |> Map.get(:date, now)
          {"all", acts, first}

        start_dt ->
          range =
            Enum.find_value(range_starts, "custom", fn {r, rs} ->
              if Date.compare(DateTime.to_date(rs), DateTime.to_date(start_dt)) == :eq, do: r
            end)

          {range, fetch_activities_between(start_dt, end_dt), start_dt}
      end

    weeks = build_weekly_buckets(activities, actual_start, end_dt)

    assign(socket,
      weeks: weeks,
      selected_range: selected_range,
      picker_ranges: picker_ranges
    )
  end

  defp fetch_all_activities do
    Repo.all(
      from(a in Activity,
        where: a.type == "Run",
        order_by: [asc: a.date],
        select: %{
          date: a.date,
          distance_meters: a.distance_meters,
          duration_seconds: a.duration_seconds,
          elevation_meters: a.elevation_meters
        }
      )
    )
  end

  defp fetch_activities_between(start_dt, end_dt) do
    Repo.all(
      from(a in Activity,
        where: a.type == "Run" and a.date >= ^start_dt and a.date <= ^end_dt,
        order_by: [asc: a.date],
        select: %{
          date: a.date,
          distance_meters: a.distance_meters,
          duration_seconds: a.duration_seconds,
          elevation_meters: a.elevation_meters
        }
      )
    )
  end

  defp build_weekly_buckets(activities, start_dt, end_dt) do
    start_date = DateTime.to_date(start_dt)
    end_date = DateTime.to_date(end_dt)
    week_start = Date.add(start_date, -Date.day_of_week(start_date, :monday) + 1)

    by_week =
      Enum.reduce(activities, %{}, fn act, acc ->
        d = DateTime.to_date(act.date)
        wk = Date.add(d, -(Date.day_of_week(d, :monday) - 1))
        miles = act.distance_meters / @meters_per_mile
        secs = act.duration_seconds || 0
        elev = act.elevation_meters || 0

        Map.update(acc, wk, {miles, secs, elev}, fn {m, s, e} ->
          {m + miles, s + secs, e + elev}
        end)
      end)

    Stream.iterate(week_start, &Date.add(&1, 7))
    |> Stream.take_while(&(Date.compare(&1, end_date) != :gt))
    |> Enum.map(fn wk ->
      {miles, secs, elev} = Map.get(by_week, wk, {0.0, 0, 0})

      %{
        week: Date.to_string(wk),
        week_end: Date.to_string(Date.add(wk, 6)),
        miles: miles,
        seconds: secs,
        elev_meters: elev
      }
    end)
  end
end
