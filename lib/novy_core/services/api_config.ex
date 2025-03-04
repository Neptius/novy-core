defmodule NovyCore.APIConfig do
  @moduledoc """
  Centralise la configuration des API utilisées dans NovyCore.
  """

  def get_apis do
    %{
      stratz: %{
        url: "https://api.stratz.com/graphql",
        type: :graphql,
        headers: [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{get_env(:novy_core, :stratz_api_key)}"},
          {"User-Agent", "STRATZ_API"}
        ]
      },
      github: %{
        url: "https://api.github.com",
        type: :rest,
        headers: []
      }
    }
  end

  defp get_env(app, key) do
    Application.get_env(app, :config)[key] || raise "Missing config for #{key}"
  end
end
