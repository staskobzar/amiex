defmodule AMI.Client do
  require Logger
  use GenServer

  @timeout 3000

  def start_link(host, port) do
    GenServer.start_link(__MODULE__, [host, port])
  end

  @impl true
  def init([host, port]) do
    Process.send(self(), :connect, [])
    {:ok, %{port: port, host: host}}
  end

  @impl true
  def handle_info({:tcp, _pid, msg}, state) do
    IO.inspect(msg, label: "RECV")
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _pid}, state) do
    Logger.warn("Connection closed")
    {:noreply, connect(state)}
  end

  @impl true
  def handle_info(:connect, %{host: host, port: port} = state) do
    Logger.warn("Connecting to #{host}:#{port}")
    {:noreply, connect(state)}
  end

  @impl true
  def handle_info(:login, %{sock: sock} = state) do
    IO.inspect(state, label: "LOGIN")
    :gen_tcp.send(sock, "LOGIN\n")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %{sock: sock}) do
    :gen_tcp.close(sock)
    Logger.debug("Closing tcp connection: #{reason}")
  end

  defp connect(%{host: host, port: port} = state) do
    opts = [active: true, send_timeout: @timeout, packet: :line]

    case :gen_tcp.connect(host, port, opts) do
      {:ok, sock} ->
        Logger.debug("Connected successfully")
        Process.send(self(), :login, [])
        Map.put(state, :sock, sock)

      {:error, reason} ->
        Logger.error("Failed to connect: '#{reason}'")
        Process.send_after(self(), :connect, @timeout)
        Logger.warn("Will retry in 3 seconds...")
        state
    end
  end
end
