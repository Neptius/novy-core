import Config

config :novy_core,
  ecto_repos: [NovyCore.Repo]

config :novy_core, Novy.Mailer, adapter: Swoosh.Adapters.Local
