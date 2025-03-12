defmodule NovyCore.ApiConfig do
  @moduledoc """
  Centralise la configuration des API utilisées dans NovyCore.
  """

  def get_apis do
    %{
      stratz: %{
        type: :graphql,
        base_url: "https://api.stratz.com/graphql",
        ws_url: "wss://api.stratz.com/graphql",
        headers: [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{Application.fetch_env!(:novy_core, :stratz_api_key)}"},
          {"User-Agent", "STRATZ_API"},
          {"Sec-WebSocket-Protocol", "graphql-transport-ws"}
        ],
        timeout: 5000,
        retry_attempts: 3,
        rate_limit: :unlimited
        # rate_limit: {1, :second}
      },
      github: %{
        type: :rest,
        base_url: "https://api.github.com",
        headers: [],
        timeout: 5000,
        retry_attempts: 3,
        rate_limit: {10, :second}
      }
    }
  end

  def get_config(api) do
    Map.get(get_apis(), api)
  end
end
