# AMI
[![Elixir CI](https://github.com/staskobzar/amiex/actions/workflows/elixir.yml/badge.svg)](https://github.com/staskobzar/amiex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/staskobzar/amiex/badge.svg?branch=master)](https://coveralls.io/github/staskobzar/amiex?branch=master)
[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/staskobzar/exfastagi/blob/master/LICENSE)

Elixir AMI (Asterisk Manager Interface) library to help build Asterisk application.
Can be used to read Asterisk events and to send Actions and commands.
Can connect to one or many Asterisks and proxy all events to single handler.
Can send an action to a single Asterisk or broadcast to all established connections.

## Installation

The package can be installed by adding `amiex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:amiex, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/amiex](https://hexdocs.pm/amiex/AMI.html).

## Usage

Create module that will use AMI:
```elixir
defmodule MyAMI do
  use AMI

  def handle_message(msg, addr) do
    IO.inspect(msg, label: "handle_message from #{addr}")
    # process incoming events
    :ok
  end
end
```

AMI client can connect to Asterisk using ```start_link/1``` function using module above:

```elixir
AMI.Client.start_link({'localhost', 5447, "admin",  "5ecR37", MyAMI})
```

It is better to use AMI as supervised process and it is possible to connect
multiple Asterisk servers. For example:

```elixir
    children = [
      %{
        id: :pbx01,
        start: {
          AMI.Client,
          :start_link,
          [{'pbx01.myphones.com', 5038, "admin", "secret4", MyAMI}]
        }
      },
      %{
        id: :pbx02,
        start: {
          AMI.Client,
          :start_link,
          [{'127.0.0.1', 5038, "admin", "secret9", MyAMI}]
        }
      },
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
```

Events also can be filtered via ```handle_message/2``` function:

```elixir
  # handle FullyBooted event which is sent after successful login
  # and send QueueSummary to all Asterisks via broadcast function
  def handle_message(%{"Event" => ["FullyBooted"]} = msg, _addr) do
    {:ok, qsum} = AMI.Action.new("QueueSummary")
    AMI.Action.broadcast(qsum) # request queues summary to all Asterisks
    :ok
  end

  # handle queues summary response events
  def handle_message(%{"Event" => ["QueueSummary"]} = msg, addr) do
    # process event here
    :ok
  end

  # handle all other events
  def handle_message(msg, addr) do
    # process event here
    AMI.Client.send(addr, AMI.Action.new("Hello"))
    :ok
  end
```
