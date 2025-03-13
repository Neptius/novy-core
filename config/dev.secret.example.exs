import Config

config :novy_core,
  stratz_api_key: ""

config :novy_core, NovyCore.Repo,
  database: "novy_dev",
  username: "postgres",
  password: "password",
  hostname: "localhost",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
