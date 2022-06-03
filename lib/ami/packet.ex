defmodule AMI.Packet do
  defguardp is_valid_text(input) when is_bitstring(input) and byte_size(input) > 0
  defguardp is_valid_list(input) when is_map(input)

  @typedoc """
  AMI Event received from Asterisk. It is a map with fields as header name and
  header values. Header value is a list as AMI supports multiple fields with
  same name. For example, following AMI Event:

  ```
    Event: Status
    Name: Channels
    Var: foo=1
    Var: bar=AAA
  ```

  Will be represented as:

  ```
    %AMI.Packet{
      "Event" => ["Status"],
      "Name" => ["Channels"],
      "Var" => ["foo=1", "bar=AAA"]
    }
  ```

  """
  @type t :: map()

  @doc """
  Parse input Event text and convert to AMI.Packet

  `input` AMI event received from Asterisk
  """
  @spec parse(input :: String.t()) :: {:ok, AMI.Packet.t()} | :error
  def parse(input) when is_valid_text(input) do
    map =
      String.split(input, "\r\n")
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&String.split(&1, ~r{\s*:\s*}, parts: 2))
      |> fold

    {:ok, map}
  end

  def parse(_input) do
    {:error, :invalid_input}
  end

  @doc """
  Check if received AMI packet is event. Returns true or false
  """
  @spec is_event?(pack :: AMI.Packet.t()) :: boolean()
  def is_event?(pack) when is_valid_list(pack) do
    case field(pack, "Event") do
      {:ok, _} -> true
      _ -> false
    end
  end

  def is_event?(_map), do: false

  @doc """
  Search field value(s) in AMI Packet.

  `map` is AMI.Packet to search

  `name` field name to search
  """
  @spec field(pack :: t(), name :: String.t()) :: {:ok, list()} | {:error, :not_found}
  def field(pack, name) do
    case Enum.find(pack, fn {k, _} -> String.downcase(name) == String.downcase(k) end) do
      {_, val} -> {:ok, val}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Converts AMI.Packet to JSON format
  """
  def to_json(pack) when is_map(pack) do
    "{" <> to_json(Map.to_list(pack)) <> "}"
  end

  def to_json([{k, v} | t]) do
    ~s("#{k}":) <>
      cond do
        length(v) > 1 -> inspect(v)
        true -> ~s("#{v}")
      end <>
      cond do
        length(t) > 0 -> "," <> to_json(t)
        true -> ""
      end
  end

  def to_json([]), do: ""

  def to_json(_map), do: {:error, :invalid_input}

  defp fold(map) do
    map
    |> Enum.map(fn [k, v] -> [k, [v]] end)
    |> List.foldr(Map.new(), fn [k, v], map ->
      case Map.fetch(map, k) do
        {:ok, val} -> Map.put(map, k, v ++ val)
        _ -> Map.put(map, k, v)
      end
    end)
  end
end
