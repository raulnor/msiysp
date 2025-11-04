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
