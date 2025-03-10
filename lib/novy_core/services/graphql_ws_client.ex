defmodule NovyCore.GraphQLWSClient do
  use GenServer

  require Logger

  alias :gun, as: Gun

  alias NovyCore.ApiConfig

  # API Client

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # def stop(pid) do
  #   GenServer.call(pid, :stop)
  # end

  # Callbacks
  @impl true
  def init(opts) do
    apiConfig = ApiConfig.get_config(:stratz)

    config = %{
      host: opts[:host] || "api.stratz.com",
      port: opts[:port] || 443,
      path: opts[:path] || "/graphql",
      query: opts[:query] || "subscription { matchCount { matchCount } }",
      variables: opts[:variables] || %{},
      headers: apiConfig[:headers] || %{},
      secure: Map.get(opts, :secure, true)
    }


    {:ok, _} = Application.ensure_all_started(:gun)

    {:ok, conn_pid} = Gun.open("api.stratz.com", 443)
    {:ok, _protocol} = Gun.await_up(conn_pid)
    {:ok, conn_pid}
  end

  def handle_call({:add, a, b}, _from, state) do
    {:reply, a + b, state}
  end

  @impl true
  def handle_info(:subscribe, config) do
    # Préparer la requête GraphQL
    payload =
      Jason.encode!(%{
        query: config.query,
        variables: config.variables
      })

    # Préparer les headers HTTP
    headers =
      [
        {"content-type", "application/json"},
        {"accept", "application/json"}
      ] ++ Enum.map(config.headers, fn {k, v} -> {to_string(k), to_string(v)} end)

    # Établir la connexion websocket
    stream_ref = :gun.ws_upgrade(config.client_pid, config.path, headers)

    {:noreply, %{config | stream_ref: stream_ref}}
  end

  # Gestion des événements WebSocket
  @impl true
  def handle_info(
        {:gun_upgrade, pid, stream_ref, ["websocket"], _headers},
        %{client_pid: pid, stream_ref: stream_ref} = config
      ) do
    Logger.info("WebSocket connection established")

    # Envoyer la requête de souscription
    payload =
      Jason.encode!(%{
        type: "start",
        id: "1",
        payload: %{
          query: config.query,
          variables: config.variables
        }
      })

    :ok = :gun.ws_send(pid, stream_ref, {:text, payload})
    {:noreply, config}
  end

  @impl true
  def handle_info({:gun_ws, pid, _ref, {:text, data}}, %{client_pid: pid} = config) do
    case Jason.decode(data) do
      {:ok, response} ->
        handle_ws_message(response, config)

      {:error, _} ->
        Logger.error("Failed to decode: #{inspect(data)}")
    end

    {:noreply, config}
  end

  @impl true
  def handle_info(
        {:gun_down, pid, _protocol, _reason, _killed_streams},
        %{client_pid: pid} = config
      ) do
    Logger.warn("Connection down, attempting to reconnect...")
    Process.send_after(self(), :connect, 5000)
    {:noreply, %{config | client_pid: nil, stream_ref: nil}}
  end

  @impl true
  def handle_info({:gun_error, _pid, _stream_ref, reason}, config) do
    Logger.error("Gun error: #{inspect(reason)}")
    {:noreply, config}
  end

  @impl true
  def handle_call(:stop, _from, config) do
    if config.client_pid do
      :gun.close(config.client_pid)
    end

    {:stop, :normal, :ok, config}
  end

  # Gestionnaire de messages GraphQL
  defp handle_ws_message(%{"type" => "connection_ack"}, _config) do
    Logger.info("Subscription initialized successfully")
  end

  defp handle_ws_message(%{"type" => "data", "payload" => payload}, _config) do
    Logger.info("Received data: #{inspect(payload)}")

    # Traiter les données reçues ici (par exemple, envoyer à PubSub, mettre à jour l'état, etc.)
    # Vous pouvez également ajouter un callback ou un système d'événements
  end

  defp handle_ws_message(%{"type" => "error", "payload" => payload}, _config) do
    Logger.error("Subscription error: #{inspect(payload)}")
  end

  defp handle_ws_message(%{"type" => "complete"}, _config) do
    Logger.info("Subscription completed")
  end

  defp handle_ws_message(message, _config) do
    Logger.debug("Unhandled message: #{inspect(message)}")
  end
end
