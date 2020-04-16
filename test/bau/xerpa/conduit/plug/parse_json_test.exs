defmodule Bau.Xerpa.Conduit.Plug.ParseJSONTest do
  use ExUnit.Case

  alias Bau.Xerpa.Conduit.Plug.ParseJSON
  alias Conduit.Message

  import ExUnit.CaptureLog

  test "successfully parses" do
    decoded_payload = %{"key" => "value"}
    encoded_payload = Jason.encode!(decoded_payload)

    msg =
      %Message{}
      |> Message.put_header("x-request-id", "request-id")
      |> Message.put_body(encoded_payload)

    next = fn x -> x end

    out_msg = ParseJSON.call(msg, next, [])

    assert out_msg ==
             msg
             |> Message.put_body(decoded_payload)
             |> Message.put_content_type("application/json")
  end

  test "parse failure" do
    invalid_payload = "{}}"

    msg =
      %Message{}
      |> Message.put_header("x-request-id", "request-id")
      |> Message.put_header("exchange", "exchange")
      |> Message.put_body(invalid_payload)
      |> Message.put_new_correlation_id("correlation-id")
      |> Message.put_source("queue")

    next = fn _ -> raise "should not be called" end

    logs =
      capture_log(
        [
          colors: [enabled: false],
          metadata: :all,
          format: "$time $metadata [$level] $levelpad$message\n"
        ],
        fn ->
          out_msg = ParseJSON.call(msg, next, [])
          assert out_msg == %{msg | status: :reject}
        end
      )

    assert logs =~ "invalid json message. discarding."
    assert logs =~ "(Jason.DecodeError) unexpected byte at position 2: 0x7D ('}')"
    assert logs =~ "request_id=request-id"
    assert logs =~ "correlation_id=correlation-id"
    assert logs =~ "queue=queue"
    assert logs =~ "exchange=exchange"
  end
end
