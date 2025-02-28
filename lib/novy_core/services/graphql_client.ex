defmodule NovyCore.Services.GraphQLClient do
  use GenServer
  require Logger

  @moduledoc """
  Un client GraphQL générique utilisant Finch pour exécuter les requêtes de manière asynchrone.
  Gère le cache, le parallélisme, la limitation de débit, la gestion avancée des erreurs,
  les retries et un circuit breaker avec réinitialisation automatique.
  """

  alias Cachex, as: Cache

  @cache_name :graphql_cache
  @finch_pool NovyCore.Finch
  @rate_limit_interval 1000 # 1 requête par seconde max (ajustable)
  @default_timeout 5000 # Timeout pour les requêtes HTTP
  @max_retries 3 # Nombre maximum de retries
  @circuit_breaker_threshold 5 # Nombre d'erreurs consécutives avant d'ouvrir le circuit breaker
  @circuit_reset_time 60000 # Temps avant la réinitialisation du circuit breaker (1 min)

  ## API Publique

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{error_count: %{}, last_error_time: %{}}, name: __MODULE__)
  end

  def execute_query(api, query, variables \\ %{}) do
    case NovyCore.Services.APIManager.get_api_config(api) do
      %{url: url, headers: headers} when is_binary(url) and is_list(headers) ->
        GenServer.call(__MODULE__, {:execute, url, query, variables, headers})
      _ ->
        {:error, :invalid_api}
    end
  end

  def execute_query_async(url, query, variables \\ %{}) do
    Task.Supervisor.start_child(NovyCore.TaskSupervisor, fn ->
      GenServer.cast(__MODULE__, {:execute, url, query, variables})
    end)
  end

  ## Callbacks GenServer

  @impl true
  def init(_) do
    Cache.start_link(name: @cache_name)
    {:ok, %{error_count: %{}, last_error_time: %{}, last_request_time: 0}}
  end

  @impl true
  def handle_call({:execute, url, query, variables, headers}, _from, state) do
    cache_key = {url, query, variables} |> :erlang.phash2() |> Integer.to_string()

    case Cache.get(@cache_name, cache_key) do
      {:ok, result} when not is_nil(result) -> {:reply, {:ok, result}, state}
      _ ->
        if circuit_open?(url, state) do
          {:reply, {:error, :circuit_open}, state}
        else
          wait_for_rate_limit(state)
          task = Task.Supervisor.async_nolink(NovyCore.TaskSupervisor, fn ->
            execute_with_retries(url, query, variables, headers, @max_retries)
          end)
          result = Task.yield(task, @default_timeout) || Task.shutdown(task, :brutal_kill)
          handle_result(result, cache_key, url, state)
        end
    end
  end

  defp execute_with_retries(url, query, variables, headers, retries) do
    case execute_request(url, query, variables, headers) do
      {:ok, response} -> {:ok, response}
      {:error, _reason} when retries > 0 ->
        :timer.sleep(500)
        execute_with_retries(url, query, variables, headers, retries - 1)
      error -> error
    end
  end

  defp execute_request(url, query, variables, headers) do
    body = Jason.encode!(%{"query" => query, "variables" => variables})
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, @finch_pool, receive_timeout: @default_timeout) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status, body: body}} ->
        log_error({:error, {status, body}})
        {:error, {status, body}}

      {:error, reason} ->
        log_error({:error, reason})
        {:error, reason}
    end
  end

  defp wait_for_rate_limit(%{last_request_time: last_time}) do
    now = System.monotonic_time(:millisecond)
    diff = now - last_time
    if diff < @rate_limit_interval, do: Process.sleep(@rate_limit_interval - diff)
  end

  defp handle_result({:ok, response}, cache_key, _url, state) do
    Cache.put(@cache_name, cache_key, response)
    {:reply, {:ok, response}, %{state | last_request_time: System.monotonic_time(:millisecond)}}
  end

  defp handle_result({:error, reason}, _cache_key, url, state) do
    new_state = update_error_count(url, state)
    log_error({:error, reason})
    {:reply, {:error, reason}, new_state}
  end

  defp handle_result(nil, _cache_key, _url, state) do
    {:reply, {:error, :timeout}, state}
  end

  defp log_error(error) do
    Logger.error("GraphQL Request Failed: #{inspect(error)}")
  end

  defp update_error_count(url, state) do
    now = System.monotonic_time(:millisecond)
    error_count = Map.get(state.error_count, url, 0) + 1
    last_error_time = Map.put(state.last_error_time, url, now)
    new_error_count = Map.put(state.error_count, url, error_count)
    %{state | error_count: new_error_count, last_error_time: last_error_time}
  end

  defp circuit_open?(url, state) do
    now = System.monotonic_time(:millisecond)
    error_count = Map.get(state.error_count, url, 0)
    last_error_time = Map.get(state.last_error_time, url, 0)

    if error_count >= @circuit_breaker_threshold and now - last_error_time < @circuit_reset_time do
      true
    else
      false
    end
  end
end
