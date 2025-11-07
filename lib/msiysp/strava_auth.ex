defmodule Msiysp.StravaAuth do
  alias Msiysp.{Activity,Repo}

  def client_id, do: System.fetch_env!("STRAVA_CLIENT_ID")
  def client_secret, do: System.fetch_env!("STRAVA_CLIENT_SECRET")

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
        body |> Jason.decode!() |> save_tokens()

      {:ok, %{status_code: status_code, body: body}} ->
        raise "Strava API error: #{status_code} - #{body}"

      {:error, %HTTPoison.Error{reason: reason}} ->
        raise "HTTP request failed: #{reason}"
    end
  end

  @token_file Path.expand("~/.config/msiysp/strava_tokens.json")

  def save_tokens(token_response) do
    @token_file |> Path.dirname() |> File.mkdir_p!()

    tokens = %{
      access_token: token_response["access_token"],
      expires_at: token_response["expires_at"],
      refresh_token: token_response["refresh_token"]
    }

    File.write!(@token_file, Jason.encode!(tokens, pretty: true))
    tokens
  end

  def load_tokens do
    case File.read(@token_file) do
      {:ok, content} -> {:ok, Jason.decode!(content)}
      error -> error
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

    save_tokens(response)
  end

  def get_valid_token do
    case load_tokens() do
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

  def fetch_activities(after_date \\ nil) do
    token = get_valid_token()
    
    params = if after_date do
      {:ok, ex_date, 0} = DateTime.from_iso8601(after_date)
      %{after: DateTime.to_unix(ex_date)}
    else
      %{per_page: 100}
    end

    HTTPoison.get!(
      "https://www.strava.com/api/v3/athlete/activities",
      [{"Authorization", "Bearer #{token}"}],
      params: params
    )
    |> Map.get(:body)
    |> Jason.decode!()
  end

  def sync_activities(after_date \\ nil) do
    activities = fetch_activities(after_date)

    Enum.each(activities, fn activity ->
      result = 
        Activity.changeset_from_strava(activity)
        |> Repo.insert(
          on_conflict: :replace_all,
          conflict_target: :strava_activity_id
        )
      case result do
      {:ok, inserted} -> 
        IO.puts("  ✓ Saved with id #{inserted.id}")
      {:error, changeset} -> 
        IO.puts("  ✗ Failed: #{inspect(changeset.errors)}")
    end
    end)
  end
end
