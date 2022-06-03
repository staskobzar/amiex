defmodule AMI.Action do
  @typedoc """
  AMI Action type is a map of headers and values.
  Values are lists because AMI protocol allows to
  have multiple headers with the same name.

  ## Example

  ```
    iex> {:ok, action} = AMI.Action.new("QueueStatus")
    iex> {:ok, action} = AMI.Action.add_field(action, "Queue", "Sales")
    {:ok,
      %{
        "Action" => ["QueueStatus"],
        "ActionID" => ["o3webr9ub391qq9hzdrqatztk"],
        "Queue" => ["Sales"]
      }}
  ```

  Automatically adds ActionID field if not yet exists. If it is required to
  have custom ActionID then use `new/2` function.
  """
  @type t :: map()

  @doc """
  Create new AMI Action and automatically add ActionID
  """
  @spec new(action :: String.t()) :: {:ok, AMI.Action.t()} | {:invalid}
  def new(action) when is_bitstring(action) do
    new(action, [])
  end

  @doc """
  Create new AMI Action with headers list. If needed to add custom
  ActionID and skip auto-generated ActionID it can be done here.

  For example:
  ```
    iex> AMI.Action.new("QueueStatus", [
      {"ActionID", "FOO-bar1"},
      {"Queue", "Sales"}
    ])
    {:ok,
     %{
      "Action" => ["QueueStatus"],
      "ActionID" => ["FOO-bar1"],
      "Queue" => ["Sales"]
    }}
  ```
  """
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

  @doc """
  Create login AMI Action with given parameters.

  `user` and `passwd` will be inserted in login Action and
  the Action will be returned as string
  """
  @spec login(user :: String.t(), passwd :: String.t()) :: String.t()
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

  @doc """
  Add new field to the Action
  """
  @spec add_field(action :: AMI.Action.t(), name :: String.t(), value :: String.t()) ::
          {:ok, AMI.Action.t()}
  def add_field(%{} = action, name, value)
      when is_bitstring(name) and is_bitstring(value) do
    action =
      case Map.fetch(action, name) do
        {:ok, val} -> Map.put(action, name, [value | val])
        _ -> Map.put(action, name, [value])
      end

    {:ok, action}
  end

  @doc """
  Convert AMI Action to string
  """
  @spec to_string(action :: AMI.Action.t()) :: String.t()
  def to_string(%{} = action) do
    action
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
