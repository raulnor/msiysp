defmodule Msiysp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Msiysp.Repo,
      {Phoenix.PubSub, name: Msiysp.PubSub},
      MsiyspWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Msiysp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
