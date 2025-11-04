defmodule Msiysp.StravaAuth do
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

    HTTPoison.post!(
      "https://www.strava.com/oauth/token",
      {:form, body}
    )
  end
end
