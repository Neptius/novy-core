defmodule NovyCore.APIWorker do
  use GenServer

  alias NovyCore.APIConfig

  def start_link(request) do
    GenServer.start_link(__MODULE__, request, [])
  end

  def init(request) do
    Task.start(fn -> execute_request(request) end)
    {:stop, :normal, nil}
  end

  # def execute_request(%{url: url, type: :rest}) do
  #   Finch.build(:get, url) |> Finch.request(NovyCore.Finch)
  # end

  # def execute_request(%{url: url, type: :graphql, query: query}) do
  #   Finch.build(:post, url, [{"Content-Type", "application/json"}], Jason.encode!(%{query: query}))
  #   |> Finch.request(NovyCore.Finch)
  # end

  def execute_request(api, path \\ "", body \\ %{}) do
    with %{url: url, type: type, headers: headers} <- APIConfig.get_apis()[api] do
      case type do
        :graphql -> send_graphql_request(url, headers, body)
        :rest -> send_rest_request("#{url}#{path}", headers, body)
      end
    else
      _ -> {:error, "API #{api} not configured"}
    end
  end

  defp send_graphql_request(url, headers, body) do
    Finch.build(:post, url, headers, Jason.encode!(body))
    |> Finch.request(NovyCore.Finch)
  end

  defp send_rest_request(url, headers, body) do
    Finch.build(:get, url, headers)
    |> Finch.request(NovyCore.Finch)
  end
end
