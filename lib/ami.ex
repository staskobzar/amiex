defmodule AMI do
  @moduledoc """
  Asterisk Management Interface
  """
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
