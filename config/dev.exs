import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

import_config "dev.secret.exs"
