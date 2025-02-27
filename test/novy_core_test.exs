defmodule NovyCoreTest do
  use ExUnit.Case
  doctest NovyCore

  test "greets the world" do
    assert NovyCore.hello() == :world
  end
end
