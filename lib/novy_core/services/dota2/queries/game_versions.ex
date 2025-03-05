defmodule NovyCore.Services.Dota2.Queries.GameVersions do
  @moduledoc """
  Module contenant les requêtes GraphQL pour obtenir les versions de jeu de Dota 2.
  """

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

    NovyCore.GraphQLClient.request(:stratz, query, variables)
  end
end
