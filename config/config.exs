# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :imgur_backend,
  ecto_repos: [ImgurBackend.Repo]

# Configures the endpoint
config :imgur_backend, ImgurBackendWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/JDeWeUG080E12ROz9FWUkeSTPlwU8XficN3Z128NhnF3pT7ZjL5ceg1TqYNJ4GO",
  render_errors: [view: ImgurBackendWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: ImgurBackend.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

# config :cors_plug,
#   origin: ["http://localhost:4000.com"],
#   max_age: 86400,
#   methods: ["GET", "POST"]
import_config "#{Mix.env}.exs"
