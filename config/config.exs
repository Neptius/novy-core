import Config

config :novy_core,
  ecto_repos: [NovyCore.Repo],
  generators: [timestamp_type: :utc_datetime]

config :novy_core, NovyCore.Finch, pools: %{default: [size: 10, count: 2]}

config :req, :legacy_headers_as_lists, true

import_config "#{config_env()}.exs"
