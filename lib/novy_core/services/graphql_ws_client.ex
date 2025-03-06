defmodule NovyCore.GraphQLWSClient do
  use GenServer
  require Logger

  alias GraphQLWSClient.Event

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

    Logger.info("Connecting to WebSocket...")
    {:ok, socket} = GraphQLWSClient.start_link(url: "wss://api.stratz.com/graphql")

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

    {:ok,
     %{
       socket: socket,
       # subscription_id: subscription_id,
       monitor: Process.monitor(socket)
     }}
  end





  @impl true
  def terminate(_reason, %{socket: nil}), do: :ok

  def terminate(_reason, %{socket: socket, subscription_id: subscription_id}) do
    GraphQLWSClient.unsubscribe(socket, subscription_id)
  end

  @impl true
  def handle_info(
        {:DOWN, monitor, :process, socket, reason},
        %{monitor: monitor, socket: socket} = state
      ) do
    IO.puts("Socket closed")
    {:stop, reason, %{state | socket: nil, subscription_id: nil}}
  end

  def handle_info(
        %Event{type: :complete, subscription_id: subscription_id},
        %{subscription_id: subscription_id} = state
      ) do
    IO.puts("complete")
    {:noreply, state}
  end

  def handle_info(
        %Event{type: :next, subscription_id: subscription_id, payload: payload},
        %{subscription_id: subscription_id} = state
      ) do
    IO.inspect(payload)
    {:noreply, state}
  end

  def handle_info(
        %Event{type: :error, subscription_id: subscription_id, payload: error},
        %{subscription_id: subscription_id} = state
      ) do
    IO.inspect(error, label: "error")
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
