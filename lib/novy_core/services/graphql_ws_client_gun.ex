# defmodule NovyCore.GraphQLWSClientGun do
#   @doc """
#   GraphQL WebSocket Client
#   """
#   use GenServer

#   alias NovyCore.ApiConfig

#   require Logger

#   @init_message %{type: "connection_init", payload: %{}}

#   def start_link do
#     opts = []

#     apiConfig = ApiConfig.get_config(:stratz)
#     ws_url = apiConfig[:ws_url]

#     state = %{}

#     GenServer.start_link(__MODULE__, state)
#   end

#   @impl true
#   def init(state) do
#     {:ok, pid} = :gun.open("wss://api.stratz.com/graphql", 443)


#     {:ok, state}
#   end

# end
