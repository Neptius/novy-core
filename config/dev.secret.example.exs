import Config

config :novy_core, NovyCore.Repo,
  database: "novy_core_repo",
  username: "postgres",
  password: "pass",
  hostname: "localhost",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
