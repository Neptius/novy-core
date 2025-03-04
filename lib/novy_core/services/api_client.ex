defmodule NovyCore.APIClient do
  use GenServer

  alias NovyCore.APIWorker
  alias NovyCore.APIWorkerSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_call({:sync_request, request}, _from, state) do
    result = APIWorker.execute_request(request)
    {:reply, result, state}
  end

  def handle_cast({:async_request, request}, state) do
    DynamicSupervisor.start_child(APIWorkerSupervisor, {APIWorker, request})
    {:noreply, state}
  end

  # NovyCore.APIClient.sync_request(%{url: "https://api.github.com/users/defunkt", type: :rest})
  def sync_request(request), do: GenServer.call(__MODULE__, {:sync_request, request})

  # NovyCore.APIClient.async_request(%{api: :github, path: "/users/neptius"})
  def async_request(request), do: GenServer.cast(__MODULE__, {:async_request, request})
end
