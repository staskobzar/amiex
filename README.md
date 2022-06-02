# AMI

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `amiex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:amiex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/amiex](https://hexdocs.pm/amiex).

## Example
```elixir
  def start() do
    user = "amiproxy"
    pass = "aix8Uk2aefoo"

    ch1 = %{
      id: :pbx01,
      start: {AMI.Client, :start_link, [{'localhost', 12345, user, pass, Foo}]}
    }

    ch2 = %{
      id: :pbx02,
      start: {AMI.Client, :start_link, [{'localhost', 12346, user, pass, Foo}]}
    }

    Supervisor.start_link([ch1, ch2], strategy: :one_for_one)
  end

defmodule Foo do
  use AMI

  def handle_message(%{"Event" => ["FullyBooted"]} = msg, addr) do
    IO.inspect(msg, label: "handle_message filter")
    {:ok, reload} = AMI.Action.new("Reload", [])
    {:ok, qsum} = AMI.Action.new("QueueSummary", [])
    {:ok, qstat} = AMI.Action.new("QueueStatus", [])
    AMI.Client.send(reload, addr)
    AMI.Client.send(qsum, addr)
    AMI.Client.send(qstat, addr)
  end

  def handle_message(msg, addr) do
    IO.inspect(msg, label: "handle_message from #{addr}")
  end
end
```
