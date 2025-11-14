import Config

# Configure Mix tasks and generators
config :msiysp,
  ecto_repos: [Msiysp.Repo]

# Configure database
config :msiysp, Msiysp.Repo,
  database: Path.expand("../msiysp_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# Configure Phoenix endpoint
config :msiysp, MsiyspWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MsiyspWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Msiysp.PubSub,
  live_view: [signing_salt: "msiysp_secret"],
  http: [ip: {127, 0, 0, 1}, port: 4001],
  secret_key_base: "msiysp_dev_secret_key_base_at_least_64_bytes_long_for_security_purposes",
  server: true

# Configure Phoenix generators
config :phoenix, :json_library, Jason
