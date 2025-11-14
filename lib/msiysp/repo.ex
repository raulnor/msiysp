defmodule Msiysp.Repo do
  use Ecto.Repo,
    otp_app: :msiysp,
    adapter: Ecto.Adapters.SQLite3
end
