defmodule NovyCore.Services.APIManager do
  @moduledoc """
  Gère les configurations des différentes APIs (URL, headers, tokens, etc.).
  """

  @apis %{
    dota2: %{
      url: "https://api.stratz.com/graphql",
      headers: [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{Application.compile_env(:novy_core, :config)[:stratz_api_key]}"},
        {"User-Agent", "STRATZ_API"}
      ]
    },
    some_other_api: %{
      url: "https://some-other-api.com/graphql",
      headers: [
        {"Authorization", "Bearer #{System.get_env("OTHER_API_TOKEN")}"},
        {"Content-Type", "application/json"}
      ]
    }
  }

  @doc """
  Retourne la configuration de l'API demandée.
  """
  def get_api_config(api_name) do
    Map.get(@apis, api_name, %{})
  end
end
