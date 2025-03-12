defmodule NovyCore.GraphQLWSClient do
  @doc """
  GraphQL WebSocket Client
  """
  use WebSockex

  alias NovyCore.ApiConfig

  require Logger

  @init_message %{type: "connection_init", payload: %{}}

  def start_link do
    opts = []
    apiConfig = ApiConfig.get_config(:stratz)
    ws_url = apiConfig[:ws_url]

    state = %{
      subscriptions: %{},
      next_id: 1,
      ping_timer: nil,
      connection_params: Keyword.get(opts, :connection_params, %{}),
      on_connected: Keyword.get(opts, :on_connected)
    }

    WebSockex.start_link(ws_url, __MODULE__, state,
      extra_headers: apiConfig[:headers],
      debug: [:trace],
      handle_initial_conn_failure: true
    )
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to GraphQL server")

    WebSockex.cast(self(), {:connection_init})
    {:ok, state}
  end


  def handle_cast({:connection_init}, state) do
    init_message = %{@init_message | payload: state.connection_params}
    {:reply, {:text, Jason.encode!(init_message)}, state}
  end





  def handle_frame({:text, msg}, state) do
    IO.inspect("handle_frame: text")
    IO.inspect(msg)

    {:ok, state}
  end

  def handle_info(_, state) do
    Logger.info("handle_info")
    {:ok, state}
  end
end
