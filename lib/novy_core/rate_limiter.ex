defmodule NovyCore.RateLimiter do
  use Hammer, backend: :ets
end
