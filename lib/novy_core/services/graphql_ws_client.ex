defmodule NovyCore.GraphQLWSClient do
  @moduledoc """
  GraphQL WebSocket Client
  """
  use WebSockex

  alias NovyCore.ApiConfig

  require Logger

  @init_message %{type: "connection_init", payload: %{}}

  def start_link do
    api_config = ApiConfig.get_config(:stratz)
    ws_url = api_config[:ws_url]
    headers = api_config[:headers]
    state = %{}

    WebSockex.start_link(ws_url, __MODULE__, state,
      extra_headers: headers
      # debug: [:trace]
    )
  end

  def stop(pid) do
    WebSockex.cast(pid, {:close})
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to GraphQL server")
    WebSockex.cast(self(), {:connection_init})
    {:ok, state}
  end

  def handle_ping(_conn, state) do
    Logger.info("Ping received")
    {:ok, state}
  end

  def handle_pong(_conn, state) do
    Logger.info("Pong received")
    {:ok, state}
  end

  def handle_cast({:connection_init}, state) do
    {:reply, {:text, Jason.encode!(@init_message)}, state}
  end

  def handle_cast({:subscribe}, state) do
    id = UUID.uuid4()

    subscription_query = """
    subscription {
      matchCount {
        matchCount
      }
    }
    """

    subscription_message = %{
      type: "subscribe",
      id: id,
      payload: %{
        query: subscription_query,
        variables: %{}
      }
    }

    {:reply, {:text, Jason.encode!(subscription_message)}, state}
  end

  def handle_cast({:close}, state) do
    Logger.info("Closing connection")
    {:close, state}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode!(msg) do
      %{"type" => "connection_ack"} ->
        Logger.info("Connection acknowledged")
        WebSockex.cast(self(), {:subscribe})
        {:ok, state}

      _ ->
        Logger.info("Unhandled message: #{msg}")
        {:ok, state}
    end
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end
end
