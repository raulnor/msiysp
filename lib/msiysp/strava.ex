defmodule Msiysp.Strava do
  alias Msiysp.{Activity, Repo}

  # Config file for IDs and tokens
  @config_file Path.expand("~/.config/msiysp/strava_config.json")

  def load_config do
    case File.read(@config_file) do
      {:ok, content} -> {:ok, Jason.decode!(content)}
      error -> error
    end
  end

  def save_config(partial_config) do
    @config_file |> Path.dirname() |> File.mkdir_p!()

    existing_config =
      case File.read(@config_file) do
        {:ok, content} -> Jason.decode!(content)
        {:error, _} -> %{}
      end

    new_config = Map.merge(existing_config, partial_config)

    File.write!(@config_file, Jason.encode!(new_config, pretty: true))
    new_config
  end

  def client_id do
    {:ok, config} = load_config()
    config["client_id"] || raise "client_id not set in #{@config_file}"
  end

  def client_secret do
    {:ok, config} = load_config()
    config["client_secret"] || raise "client_secret not set in #{@config_file}"
  end

  def get_auth_url do
    params =
      URI.encode_query(%{
        client_id: client_id(),
        response_type: "code",
        redirect_uri: "http://localhost:5000/exchange_token",
        approval_prompt: "force",
        scope: "activity:read_all,read_all"
      })

    "https://www.strava.com/oauth/authorize?#{params}"
  end

  def open_browser do
    System.cmd("open", [get_auth_url()])
  end

  def exchange_code(code) do
    body = %{
      client_id: client_id(),
      client_secret: client_secret(),
      code: code,
      grant_type: "authorization_code"
    }

    case HTTPoison.post("https://www.strava.com/oauth/token", {:form, body}) do
      {:ok, %{status_code: 200, body: body}} ->
        body |> Jason.decode!() |> save_config()

      {:ok, %{status_code: status_code, body: body}} ->
        raise "Strava API error: #{status_code} - #{body}"

      {:error, %HTTPoison.Error{reason: reason}} ->
        raise "HTTP request failed: #{reason}"
    end
  end

  def expired?(tokens) do
    expires_at = tokens["expires_at"]
    System.system_time(:second) >= expires_at - 60
  end

  def refresh_access_token(refresh_token) do
    body = %{
      client_id: client_id(),
      client_secret: client_secret(),
      grant_type: "refresh_token",
      refresh_token: refresh_token
    }

    response =
      HTTPoison.post!(
        "https://www.strava.com/oauth/token",
        {:form, body}
      )
      |> Map.get(:body)
      |> Jason.decode!()

    save_config(response)
  end

  def get_valid_token do
    case load_config() do
      {:ok, tokens} ->
        if expired?(tokens) do
          refresh_access_token(tokens["refresh_token"])["access_token"]
        else
          tokens["access_token"]
        end

      {:error, _} ->
        raise "Loading token failed!"
    end
  end

  def to_strava_date_param(iso8601string) do
    {:ok, e_date, 0} = DateTime.from_iso8601(iso8601string)
    DateTime.to_unix(e_date)
  end

  def fetch_activities(params \\ %{per_page: 100}) do
    token = get_valid_token()

    HTTPoison.get!(
      "https://www.strava.com/api/v3/athlete/activities",
      [{"Authorization", "Bearer #{token}"}],
      params: params
    )
    |> Map.get(:body)
    |> Jason.decode!()
  end

  def sync_activities(params \\ %{per_page: 100}) do
    activities = fetch_activities(params)

    Enum.each(activities, fn activity ->
      result =
        Activity.changeset_from_strava(activity)
        |> Repo.insert(
          on_conflict: :replace_all,
          conflict_target: :strava_activity_id
        )

      case result do
        {:ok, inserted} ->
          IO.puts("  ✓ Saved with id #{inserted.id} - #{inserted.date}")

        {:error, changeset} ->
          IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
      end
    end)
  end

  def sync_all_activities(date_ptr \\ nil) do
    params =
      if date_ptr do
        %{before: date_ptr |> to_strava_date_param}
      else
        %{per_page: 100}
      end

    activities = fetch_activities(params)

    Enum.each(activities, fn activity ->
      Activity.changeset_from_strava(activity)
      |> Repo.insert(
        on_conflict: :replace_all,
        conflict_target: :strava_activity_id
      )
    end)

    case activities do
      [] ->
        IO.puts("✓ Sync complete! No more activities found.")

      _ ->
        IO.puts("✓ Sync continuing after adding #{Enum.count(activities)} rows.")
        earliest_activity = List.last(activities)
        sync_all_activities(earliest_activity["start_date"])
    end
  end
end
