defmodule NovyCore.GraphQLWSClient do
  use GenServer

  require Logger

  ## ==============================
  ## PUBLIC API
  ## ==============================

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## ==============================
  ## CALLBACKS
  ## ==============================

  @impl true
  def init(_) do
    # opts = %{
    #   host: "api.stratz.com/graphql",
    #   port: 443,
    #   path: "/graphql",
    #   headers: [
    #     {"Authorization", "Bearer #{Application.get_env(:novy_core, :config)[:stratz_api_key]}"},
    #     {"User-Agent", "STRATZ_API"}
    #   ]
    # }

    Logger.info("Ensuring Gun application is started...")

    {:ok, _} = Application.ensure_all_started(:gun)

    Logger.info("Connecting to WebSocket...")

    test = :gun.open("api.stratz.com", 443, %{})
    IO.inspect(test)

    # Logger.info("Subscribing to MatchCount event...")

    # subscription_id =
    #   GraphQLWSClient.subscribe!(socket, """
    #     subscription MatchCount {
    #       matchCount {
    #         matchCount
    #       }
    #     }
    #   """)

    # Logger.info("Subscribed to MatchCount event with ID: #{subscription_id}")

    {:ok, %{}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
