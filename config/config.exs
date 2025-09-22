# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ojol_mvp,
  ecto_repos: [OjolMvp.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :ojol_mvp, OjolMvpWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: OjolMvpWeb.ErrorHTML, json: OjolMvpWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OjolMvp.PubSub,
  live_view: [signing_salt: "3ZVPbJwg"]

# Configures the mailer
config :ojol_mvp, OjolMvp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  ojol_mvp: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  ojol_mvp: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ojol_mvp, :routing,
  # Public server
  osrm_base_url: "https://router.project-osrm.org",
  timeout: 15_000

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ojol_mvp, OjolMvp.Guardian,
  issuer: "ojol_mvp",
  # Generate with: mix guardian.gen.secret
  secret_key: "your-secret-key-here"

config :hammer,
  backend: {
    Hammer.Backend.ETS,
    [
      expiry_ms: 60_000 * 60 * 4,
      cleanup_interval_ms: 60_000 * 10
    ]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
