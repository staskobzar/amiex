defmodule AMI.ClientTest do
  use ExUnit.Case, async: true
  @moduletag :capture_log

  test "connect and login" do
    {:ok, sock} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port} = :inet.port(sock)
    pid = self()
    spawn(fn -> accept_respond(sock, pid, []) end)
    AMI.Client.start_link({'localhost', port, "admin", "pwd123", MockAMI})

    {:ok, pack} = recv()
    assert String.starts_with?(pack, "Action: Login")
    assert String.contains?(pack, "Secret: pwd123")

    tab = :ets.tab2list(:amiex_socks_table)
    assert length(tab) == 1
    [{addr, _}] = tab
    assert String.starts_with?(addr, "localhost:")
  end

  test "connect multiple servers and store locally" do
    {:ok, sock1} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port1} = :inet.port(sock1)
    {:ok, sock2} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port2} = :inet.port(sock2)
    pid = self()
    spawn(fn -> accept_respond(sock1, pid, []) end)
    spawn(fn -> accept_respond(sock2, pid, []) end)
    AMI.Client.start_link({'localhost', port1, "admin1", "pwd123", MockAMI})
    AMI.Client.start_link({'localhost', port2, "admin2", "pwd123", MockAMI})
    {:ok, pack1} = recv()
    {:ok, pack2} = recv()
    assert String.contains?(pack1, "Username: admin")
    assert String.contains?(pack2, "Username: admin")

    tab = :ets.tab2list(:amiex_socks_table)
    assert length(tab) == 2
  end

  test "send action" do
    {:ok, sock} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port} = :inet.port(sock)
    pid = self()
    resp = "Response: Success\r\nMessage: OK\r\n\r\n"
    spawn(fn -> accept_respond(sock, pid, [resp]) end)
    AMI.Client.start_link({'localhost', port, "admin", "pwd123", MockAMI})

    {:ok, pack} = recv()
    assert String.starts_with?(pack, "Action: Login")

    {:ok, action} = AMI.Action.new("Status")
    AMI.Client.send(action, "localhost:#{port}")
    {:ok, pack} = recv()
    assert String.starts_with?(pack, "Action: Status")
  end

  test "send action fails" do
    {:ok, sock} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port} = :inet.port(sock)
    pid = self()
    spawn(fn -> accept_respond(sock, pid, []) end)
    AMI.Client.start_link({'localhost', port, "admin", "pwd123", MockAMI})
    :gen_tcp.close(sock)
    {:ok, action} = AMI.Action.new("Status")
    AMI.Client.send(action, "localhost:#{port}")
    Process.sleep(100)
    tab = :ets.tab2list(:amiex_socks_table)
    assert length(tab) == 0
  end

  test "fail to connect" do
    AMI.Client.start_link({'localhost', 0, "admin", "pwd123", MockAMI})
    Process.sleep(100)
    tab = :ets.tab2list(:amiex_socks_table)
    assert length(tab) == 0
  end

  test "broadcast action" do
    {:ok, sock1} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port1} = :inet.port(sock1)
    {:ok, sock2} = :gen_tcp.listen(0, [:binary, packet: 0, active: false])
    {:ok, port2} = :inet.port(sock2)
    resp = "Response: Success\r\nMessage: OK\r\n\r\n"
    pid = self()
    spawn(fn -> accept_respond(sock1, pid, [resp]) end)
    spawn(fn -> accept_respond(sock2, pid, [resp]) end)
    AMI.Client.start_link({'localhost', port1, "admin1", "pwd123", MockAMI})
    AMI.Client.start_link({'localhost', port2, "admin2", "pwd123", MockAMI})
    {:ok, pack1} = recv()
    {:ok, pack2} = recv()
    assert String.contains?(pack1, "Username: admin")
    assert String.contains?(pack2, "Username: admin")

    {:ok, action} = AMI.Action.new("ReloadAll")
    AMI.Client.broadcast(action)
    {:ok, pack1} = recv()
    {:ok, pack2} = recv()
    assert String.contains?(pack1, "Action: ReloadAll")
    assert String.contains?(pack2, "Action: ReloadAll")
  end

  defp accept_respond(psock, pid, responds) do
    {:ok, sock} = :gen_tcp.accept(psock)
    :gen_tcp.send(sock, 'Asterisk Call Manager/2.10.9\n')
    responder(sock, pid, responds)
  end

  defp responder(sock, pid, [resp | tail]) do
    :gen_tcp.send(sock, resp)
    {:ok, pack} = :gen_tcp.recv(sock, 0)
    send(pid, {:ok, pack})
    responder(sock, pid, tail)
  end

  defp responder(sock, pid, []) do
    {:ok, pack} = :gen_tcp.recv(sock, 0)
    send(pid, {:ok, pack})
  end

  defp recv do
    receive do
      {:ok, pack} ->
        {:ok, pack}

      err ->
        raise "Error login. Unexpected message #{err} "
    after
      2000 -> raise "Timeout recv. Expected Login AMI packet on connection"
    end
  end
end

defmodule MockAMI do
  use AMI

  def handle_message(_msg, _addr), do: :ok
end
