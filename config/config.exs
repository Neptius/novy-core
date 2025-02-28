import Config

config :novy_core,
  ecto_repos: [NovyCore.Repo],
  generators: [timestamp_type: :utc_datetime]

import_config "#{config_env()}.exs"
