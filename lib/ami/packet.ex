defmodule AMI.Packet do
  defguardp is_valid_text(input) when is_bitstring(input) and byte_size(input) > 0
  defguardp is_valid_list(input) when is_map(input)

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

  def is_event?(map) when is_valid_list(map) do
    case field(map, "Event") do
      {:ok, _} -> true
      _ -> false
    end
  end

  def is_event?(_map), do: false

  def field(map, name) do
    case Enum.find(map, fn {k, _} -> String.downcase(name) == String.downcase(k) end) do
      {_, val} -> {:ok, val}
      _ -> {:not_found}
    end
  end

  def to_json(map) when is_map(map) do
    "{" <> to_json(Map.to_list(map)) <> "}"
  end

  def to_json([h | t]) do
    {k, v} = h

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

  def to_json([]) do
    ""
  end

  def to_json(_map) do
    {:invalid_input}
  end

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
