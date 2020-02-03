defmodule Bau.Xerpa.TracingTest do
  use ExUnit.Case

  alias Bau.Xerpa.Tracing

  test "get_request_id and put_request_id" do
    refute Tracing.get_request_id()
    Tracing.put_request_id("request-id")
    assert Tracing.get_request_id() == "request-id"
  end
end
