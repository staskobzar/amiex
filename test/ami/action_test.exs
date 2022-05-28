defmodule AMI.ActionTest do
  use ExUnit.Case, async: true

  test "#add_field" do
    map = %{}
    assert {:ok, map} = AMI.Action.add_field(map, "ActionID", "FOO-0feed123")
    assert {:ok, map} = AMI.Action.add_field(map, "Variable", "Bar")
    assert {:ok, map} = AMI.Action.add_field(map, "Value", "1")

    %{"ActionID" => [val]} = map
    assert val == "FOO-0feed123"
    %{"Variable" => [val]} = map
    assert val == "Bar"
    %{"Value" => [val]} = map
    assert val == "1"

    assert {:ok, map} = AMI.Action.add_field(map, "Value", "2")
    assert {:ok, map} = AMI.Action.add_field(map, "Value", "3")
    %{"Value" => val} = map
    assert val == ["3", "2", "1"]

    assert {:invalid} = AMI.Action.add_field(map, "", "100")
  end

  test "#new with only action" do
    assert {:ok, map} = AMI.Action.new("Agents")
    assert map_size(map) == 2
  end

  test "#new single field" do
    assert {:ok, map} = AMI.Action.new("Agents", [])
    assert map_size(map) == 2, "automatically adds action id"

    %{"Action" => [val]} = map
    assert val == "Agents"

    %{"ActionID" => [val]} = map
    assert is_bitstring(val) && String.length(val) > 0
  end

  test "#new with fields list" do
    assert {:ok, map} =
             AMI.Action.new("QueueStatus", [
               {"ActionID", "FOO-bar1"},
               {"Queue", "Sales"}
             ])

    %{"Action" => [val]} = map
    assert val == "QueueStatus"

    %{"ActionID" => [val]} = map
    assert val == "FOO-bar1"

    %{"Queue" => [val]} = map
    assert val == "Sales"

    assert {:invalid} = AMI.Action.new("Foo", [{"", ""}])
  end

  test "#login action" do
    packet = AMI.Action.login("admin", "pa55w0rd")

    {:ok, rx} =
      Regex.compile(
        "Action: Login\r\n" <>
          "ActionID: [a-z0-9]+\r\nSecret: pa55w0rd\r\n" <>
          "Username: admin\r\n\r\n"
      )

    assert String.match?(packet, rx)
  end

  test "#new fail on invalid action" do
    assert {:invalid} = AMI.Action.new("", [])
    assert {:invalid} = AMI.Action.new("   ", [])
    assert {:invalid} = AMI.Action.new(nil, [])
  end

  test "#to_json" do
    assert {:ok, map} = AMI.Action.new("Agents", [{"ActionID", "foo0f"}])

    assert ~s(Action: Agents\r\nActionID: foo0f\r\n\r\n) ==
             AMI.Action.to_string(map)

    assert {:ok, map} = AMI.Action.add_field(map, "Var", "a=1")
    assert {:ok, map} = AMI.Action.add_field(map, "Var", "b=2")

    assert ~s(Action: Agents\r\nActionID: foo0f\r\n) <>
             ~s(Var: a=1\r\nVar: b=2\r\n\r\n) ==
             AMI.Action.to_string(map)

    assert {:ok, map} =
             AMI.Action.new("Agents", [
               {"ActionID", "foo"},
               {"Foo", "123"},
               {"Bar", "abc"}
             ])

    assert ~s(Action: Agents\r\nActionID: foo\r\n) <>
             ~s(Bar: abc\r\nFoo: 123\r\n\r\n) ==
             AMI.Action.to_string(map)
  end
end
