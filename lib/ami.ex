defmodule AMI do
  @moduledoc """
  Asterisk Management Interface handler to use in an appliction.

  AMI module is using GenServer in background and executes code asynchronously.
  It will also fit into a supervisor tree.

  This module is supposed to be used in `AMI.Client.start_link/1`. When
  client is connected all incomming messages will go to `handle_message/2`.

  ## Usage

  ```
    defmodule MyAMI do
      use AMI

      @impl true
      def handle_message(event, addr) do
        IO.inspect(event, label: "RECV EVENT")
        IO.inspect(addr, label: "FROM")
        :ok
      end
    end
  ```

  """
  @doc """
  All events delivered by AMI connection (or connections) will get here.

  `msg` is AMI.Packet that contains parsed AMI Event.

  `addr` is string that represents address of Asterisk from which
  Event was sent. This addres is also used to send Actions
  """
  @callback handle_message(msg :: AMI.Packet.t(), addr :: String.t()) :: :ok | :error

  @doc false
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
