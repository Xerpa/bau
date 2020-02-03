defmodule Bau.Xerpa.Conduit.Plug.RequestIdTest do
  use ExUnit.Case

  alias Bau.Xerpa.Conduit.Plug.RequestId
  alias Bau.Xerpa.Tracing
  alias Conduit.Message

  describe "incoming message" do
    test "copies x-request-id to metadata when it exists" do
      in_msg = Message.put_header(%Message{}, "x-request-id", "request-id")

      out_msg = RequestId.call(in_msg, &id/1, [])

      assert Tracing.get_request_id() == "request-id"
      assert Message.get_header(out_msg, "x-request-id") == "request-id"
    end

    test "does nothing when x-request-id is missing" do
      in_msg = %Message{}
      out_msg = RequestId.call(in_msg, &id/1, [])

      refute Tracing.get_request_id()
      refute Message.get_header(out_msg, "x-request-id")
    end
  end

  describe "outgoind message" do
    test "copies request-id to header when it exists" do
      Tracing.put_request_id("request-id")
      in_msg = %Message{}
      out_msg = RequestId.call(in_msg, &id/1, [])

      assert Tracing.get_request_id() == "request-id"
      assert Message.get_header(out_msg, "x-request-id") == "request-id"
    end

    test "does nothing when request-id is missing" do
      in_msg = %Message{}
      out_msg = RequestId.call(in_msg, &id/1, [])

      refute Tracing.get_request_id()
      refute Message.get_header(out_msg, "x-request-id")
    end
  end

  defp id(x), do: x
end
