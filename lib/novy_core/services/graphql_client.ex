# defmodule NovyCore.GraphQLClient do
#   @moduledoc """
#   Client GraphQL générique utilisant Finch pour les requêtes HTTP.
#   """

#   alias NovyCore.ApiConfig
#   alias NovyCore.RateLimiter

#   # Expiration après 10 minutes
#   @default_cache_ttl :timer.minutes(5)

#   def request(api_name, query, variables \\ %{}, opts \\ []) do
#     config = ApiConfig.get_config(api_name)

#     if config do
#       case check_rate_limit(api_name, config[:rate_limit]) do
#         :ok -> perform_request(api_name, query, variables, opts)
#         {:error, reason} -> {:error, reason}
#       end
#     else
#       {:error, :unknown_api}
#     end
#   end

#   defp perform_request(api_name, query, variables, opts) do
#     cache_key = generate_cache_key(api_name, query, variables)

#     case Cachex.get(NovyCore.Cache, cache_key) do
#       {:ok, nil} -> fetch_from_api(api_name, query, variables, opts, cache_key)
#       {:ok, cached_response} -> {:ok, cached_response}
#       {:error, _} -> fetch_from_api(api_name, query, variables, opts, cache_key)
#     end
#   end

#   defp fetch_from_api(api_name, query, variables, opts, cache_key) do
#     config = ApiConfig.get_config(api_name)

#     body = Jason.encode!(%{"query" => query, "variables" => variables})

#     request = Finch.build(:post, config[:base_url], config[:headers], body)
#     timeout = Keyword.get(opts, :timeout, config[:timeout] || 5000)
#     retries = Keyword.get(opts, :retries, config[:retry_attempts] || 3)

#     case execute_request(request, retries, timeout) do
#       {:ok, response} ->
#         Cachex.put(NovyCore.Cache, cache_key, response, ttl: @default_cache_ttl)
#         {:ok, response}

#       {:error, _} = error ->
#         error
#     end
#   end

#   defp execute_request(request, retries, timeout) do
#     case Finch.request(request, NovyCore.Finch, receive_timeout: timeout) do
#       {:ok, %Finch.Response{status: 200, body: body}} ->
#         Jason.decode(body)

#       {:ok, %Finch.Response{status: status, body: body}} ->
#         {:error, %{status: status, body: body}}

#       {:error, _reason} when retries > 0 ->
#         # max 2s
#         delay = min(trunc(:math.pow(2, 3 - retries) * 100), 2000)
#         Process.sleep(delay)
#         execute_request(request, retries - 1, timeout)

#       {:error, reason} ->
#         {:error, reason}
#     end
#   end

#   defp generate_cache_key(api_name, query, variables) do
#     key = "#{api_name}:#{query}:#{Jason.encode!(variables)}"
#     :crypto.hash(:sha256, key) |> Base.encode16()
#   end

#   defp check_rate_limit(_api_name, :unlimited), do: :ok

#   defp check_rate_limit(api_name, {limit, period}) do
#     interval =
#       case period do
#         :second -> 1_000
#         :minute -> 60_000
#         :hour -> 3_600_000
#         _ -> 1_000
#       end

#     case RateLimiter.hit("graphql:#{api_name}", interval, limit) do
#       {:allow, _count} -> :ok
#       {:deny, _limit} -> {:error, :rate_limit_exceeded}
#     end
#   end
# end
