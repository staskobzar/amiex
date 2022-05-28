defmodule AMI do
  @moduledoc """
  Asterisk Management Interface
  """
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

  @callback handle_message(msg :: map(), addr :: String.t()) :: :ok | :error
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour AMI
      def handle_message(_msg, _addr) do
        raise "attempt to call AMI but no handle_message/2 provided"
      end

      defoverridable handle_message: 2
    end
  end
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
