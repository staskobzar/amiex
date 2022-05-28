defmodule AMI.Client do
  require Logger
  use GenServer

  @timeout 3000
  @table_name :amiex_socks_table

  def start_link({host, port, user, passwd, module}) do
    case :ets.whereis(@table_name) do
      :undefined -> :ets.new(@table_name, [:named_table, :public])
      _ -> nil
    end

    GenServer.start_link(
      __MODULE__,
      [host, port, user, passwd, module],
      name: pname(host, port)
    )
  end

  def send(action, addr) do
    Logger.debug("Sending action to #{addr}")
    GenServer.cast(pname(addr), {:send, action, addr})
  end

  def broadcast(action) do
    broadcast(:ets.tab2list(@table_name), action)
  end

  def broadcast([{addr, _} | tail], action) do
    Logger.debug("Broadcast to #{addr}")
    __MODULE__.send(action, addr)
    broadcast(tail, action)
  end

  def broadcast([], _action) do
    Logger.debug("Broadcast done")
    :ok
  end

  @impl true
  def init([host, port, user, pass, module]) do
    Process.send(self(), :connect, [])

    {:ok, %{host: host, port: port, user: user, secret: pass, module: module, packet: ""}}
  end

  @impl true
  def handle_cast({:send, action, addr}, state) do
    Logger.debug("Cast action to #{addr}")

    case :ets.lookup(@table_name, addr) do
      [{^addr, sock}] ->
        sendto(sock, AMI.Action.to_string(action))

      [] ->
        Logger.error("Failed to find socket for '#{addr}' to send action")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _pid, 'Asterisk Call Manager/' ++ _}, state) do
    Logger.info("Received AMI prompt line")
    Process.send(self(), :login, [])
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:tcp, _pid, msg},
        %{packet: packet, host: host, port: port, module: mod} = state
      ) do
    packet =
      case msg do
        '\r\n' ->
          parse_msg(packet, mod, to_key(host, port))

        line ->
          packet <> to_string(line)
      end

    {:noreply, %{state | packet: packet}}
  end

  @impl true
  def handle_info({:tcp_closed, _pid}, state) do
    Logger.warn("Connection closed")
    {:noreply, connect(state)}
  end

  @impl true
  def handle_info(:connect, %{host: host, port: port} = state) do
    Logger.info("Connecting to #{host}:#{port}")
    {:noreply, connect(state)}
  end

  @impl true
  def handle_info(:login, %{sock: sock, user: user, secret: pwd} = state) do
    Logger.info("Login to AMI server with user '#{user}'")

    sendto(sock, AMI.Action.login(user, pwd))

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{sock: sock}) do
    :gen_tcp.close(sock)
    Logger.debug("AMI session is terminated")
  end

  defp connect(%{host: host, port: port} = state) do
    case tcp_connect(host, port) do
      {:ok, sock} ->
        :ets.insert(@table_name, {to_key(host, port), sock})
        Map.put(state, :sock, sock)

      {:error, reason} ->
        Logger.error("Failed to connect #{host}:#{port} - '#{reason}'")
        Process.send_after(self(), :connect, @timeout)
        Logger.warn("Will retry in #{@timeout}ms...")
        state
    end
  end

  defp tcp_connect(host, port) do
    opts = [active: true, send_timeout: @timeout, packet: :line]

    case :gen_tcp.connect(host, port, opts) do
      {:ok, sock} ->
        Logger.info("Connected to #{host}:#{port}")
        {:ok, sock}

      {:error, err} ->
        {:error, err}
    end
  end

  defp parse_msg(packet, mod, key) do
    case AMI.Packet.parse(packet) do
      {:ok, event} -> mod.handle_message(event, key)
      {:error, reason} -> Logger.warn("Failed to parse packet: #{reason}")
    end

    # return empty line in both cases to reset packet
    ""
  end

  defp sendto(sock, action) do
    case :gen_tcp.send(sock, action) do
      :ok -> Logger.debug("Successfully send AMI action")
      {:error, reason} -> Logger.error("Failed to send AMI packet: #{reason}")
    end
  end

  defp to_key(host, port), do: "#{host}:#{port}"
  defp pname(host, port), do: {:global, {__MODULE__, to_key(host, port)}}
  defp pname(addr), do: {:global, {__MODULE__, addr}}
end
