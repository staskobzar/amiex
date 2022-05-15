defmodule AMI.PacketTest do
  use ExUnit.Case, async: true

  test "empty or invalid input" do
    input =
      "Event: Newchannel\r\n" <>
        "Privilege: call,all\r\n" <>
        "Channel: PJSIP/misspiggy-00000001\r\n" <>
        "Uniqueid: 1368479157.3\r\n" <>
        "Context: inbound\r\n\r\n"

    assert {:ok, _} = AMI.Packet.parse(input)

    assert {:error, :invalid_input} = AMI.Packet.parse("")
    assert {:error, :invalid_input} = AMI.Packet.parse(nil)
  end

  test "is event" do
    input =
      "Event: Newchannel\r\n" <>
        "Privilege: call,all\r\n" <>
        "Channel: PJSIP/misspiggy-00000001\r\n" <>
        "Uniqueid: 1368479157.3\r\n" <>
        "ChannelState: 3\r\n" <>
        "Context: inbound\r\n\r\n"

    assert {:ok, map} = AMI.Packet.parse(input)
    assert AMI.Packet.is_event?(map)
    assert !AMI.Packet.is_event?([])
    assert !AMI.Packet.is_event?(nil)
    assert !AMI.Packet.is_event?("")

    assert {:ok, map} = AMI.Packet.parse("Action: Status\r\n\r\n")
    assert !AMI.Packet.is_event?(map)
  end

  test "field" do
    input =
      "Event: Newchannel\r\n" <>
        "Privilege: call,all\r\n" <>
        "Channel: PJSIP/misspiggy-00000001\r\n" <>
        "Uniqueid: 1368479157.3\r\n" <>
        "ChannelState: 3\r\n" <>
        "ChannelStateDesc: Up\r\n" <>
        "CallerIDNum: 657-5309\r\n" <>
        "CallerIDName: Miss Piggy\r\n" <>
        "ConnectedLineName:\r\n" <>
        "ConnectedLineNum:\r\n" <>
        "Variable: foo=5\r\n" <>
        "Variable: bar=Hello\r\n" <>
        "AccountCode: Pork\r\n" <>
        "Priority:\r\n" <>
        "ChanVar: SIP/000a1\r\n" <>
        "ChanVar: SIP/000a2\r\n" <>
        "ChanVar: SIP/000a3\r\n" <>
        "ChanVar: SIP/000a4\r\n" <>
        "Exten: 31337\r\n" <>
        "Context: inbound\r\n\r\n"

    assert {:ok, map} = AMI.Packet.parse(input)

    assert AMI.Packet.field(map, "Event") == {:ok, ["Newchannel"]}
    assert AMI.Packet.field(map, "privilege") == {:ok, ["call,all"]}
    assert AMI.Packet.field(map, "Variable") == {:ok, ["foo=5", "bar=Hello"]}
    assert AMI.Packet.field(map, "Priority") == {:ok, [""]}
    assert AMI.Packet.field(map, "ConnectedLineName") == {:ok, [""]}
    assert AMI.Packet.field(map, "exten") == {:ok, ["31337"]}
    assert AMI.Packet.field(map, "Context") == {:ok, ["inbound"]}

    assert AMI.Packet.field(map, "ChanVar") ==
             {:ok,
              [
                "SIP/000a1",
                "SIP/000a2",
                "SIP/000a3",
                "SIP/000a4"
              ]}

    assert AMI.Packet.field(map, "") == {:error, :not_found}
    assert AMI.Packet.field(map, "fooBar") == {:error, :not_found}
  end

  test "to_json" do
    assert AMI.Packet.to_json(nil) == {:error, :invalid_input}
    assert AMI.Packet.to_json("") == {:error, :invalid_input}
    assert AMI.Packet.to_json(Map.new()) == "{}"

    {:ok, map} = AMI.Packet.parse("Action: Status\r\n\r\n")
    assert AMI.Packet.to_json(map) == "{\"Action\":\"Status\"}"

    {:ok, map} = AMI.Packet.parse("Event: UserName\r\nName: Alice\r\n\r\n")
    assert AMI.Packet.to_json(map) == "{\"Event\":\"UserName\",\"Name\":\"Alice\"}"

    {:ok, map} = AMI.Packet.parse("Evt: Var\r\nVar: foo=bar\r\nVar: lr=true\r\n\r\n")
    assert AMI.Packet.to_json(map) == ~s({"Evt":"Var","Var":["foo=bar", "lr=true"]})

    input =
      "Event: Newchannel\r\n" <>
        "Privilege: call,all\r\n" <>
        "Channel: PJSIP/mp-0001\r\n" <>
        "Uniqueid: 1368479157.3\r\n" <>
        "Variable: foo=5\r\n" <>
        "Variable: bar=Hello\r\n" <>
        "Exten: 31337\r\n" <>
        "Priority:\r\n" <>
        "ChanVar: SIP/000a3\r\n" <>
        "ChanVar: SIP/000a4\r\n" <>
        "Context: inbound\r\n\r\n"

    want =
      ~s({"ChanVar":["SIP/000a3", "SIP/000a4"],"Channel":"PJSIP/mp-0001",) <>
        ~s("Context":"inbound","Event":"Newchannel","Exten":"31337",) <>
        ~s("Priority":"","Privilege":"call,all","Uniqueid":"1368479157.3",) <>
        ~s("Variable":["foo=5", "bar=Hello"]})

    {:ok, map} = AMI.Packet.parse(input)
    assert AMI.Packet.to_json(map) == want
  end
end
