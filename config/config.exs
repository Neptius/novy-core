import Config

config :novy_core, NovyCore.Repo,
  database: "novy_dev",
  username: "postgres",
  password: "password",
  hostname: "localhost",
  pool_size: 10

config :novy_core, ecto_repos: [NovyCore.Repo]
