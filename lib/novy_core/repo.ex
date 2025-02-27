defmodule NovyCore.Repo do
  use Ecto.Repo,
    otp_app: :novy_core,
    adapter: Ecto.Adapters.Postgres
end
