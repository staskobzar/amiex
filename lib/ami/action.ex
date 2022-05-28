defmodule AMI.Action do
  def new(action) when is_bitstring(action) do
    new(action, [])
  end

  def new(action, list)
      when is_bitstring(action) and is_list(list) do
    action = String.trim(action)

    cond do
      String.length(action) == 0 ->
        {:invalid}

      true ->
        map = %{"Action" => [action]}
        create(map, list)
    end
  end

  def new(_action, _list) do
    {:invalid}
  end

  def login(user, passwd) do
    {:ok, pack} = AMI.Action.new("Login", [])
    {:ok, pack} = AMI.Action.add_field(pack, "Username", user)
    {:ok, pack} = AMI.Action.add_field(pack, "Secret", passwd)
    AMI.Action.to_string(pack)
  end

  defp create(%{} = map, [h | tail]) do
    {k, v} = h

    case add_field(map, k, v) do
      {:ok, map} -> create(map, tail)
      _ -> {:invalid}
    end
  end

  defp create(%{} = map, []) do
    if Map.has_key?(map, "ActionID") do
      {:ok, map}
    else
      add_field(map, "ActionID", action_id())
    end
  end

  def add_field(_map, "", _value) do
    {:invalid}
  end

  def add_field(%{} = map, name, value)
      when is_bitstring(name) and is_bitstring(value) do
    map =
      case Map.fetch(map, name) do
        {:ok, val} -> Map.put(map, name, [value | val])
        _ -> Map.put(map, name, [value])
      end

    {:ok, map}
  end

  def to_string(%{} = map) do
    map
    |> Enum.map(fn {k, v} ->
      Enum.map(v, fn h -> ~s(#{k}: #{h}) end)
      |> Enum.reverse()
    end)
    |> List.flatten()
    |> List.foldr("\r\n", fn h, acc -> ~s(#{h}\r\n) <> acc end)
  end

  defp action_id() do
    base = Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9)

    List.foldr(
      Enum.to_list(0..24),
      "",
      fn _, acc -> acc <> <<Enum.random(base)>> end
    )
  end
end
