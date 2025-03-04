defmodule NovyCore.Services.Dota2.Queries.GameVersions do
  @moduledoc """
  Module contenant les requêtes GraphQL pour obtenir les versions de jeu de Dota 2.
  """

  alias NovyCore.APIClient

  @doc """
  Récupère les versions de jeu de Dota 2.
  """
  def run do
    query = """
    query {
      constants {
        gameVersions {
          id
          name
          asOfDateTime
        }
      }
    }
    """

    variables = %{}

    # Requête synchrone
    case APIClient.async_request(:stratz, query, variables) do
      {:ok, response} -> IO.inspect(response, label: "Réponse synchrone")
      {:error, reason} -> IO.inspect(reason, label: "Erreur synchrone")
    end

    # Requête asynchrone
    # GraphQLClient.execute_query_async(:dota2, query, variables)
  end
end
