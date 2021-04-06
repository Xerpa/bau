defmodule Bau.Xerpa.Tesla.Middleware.RequestIdForwarderTest do
  use ExUnit.Case, async: true

  alias Bau.Xerpa.Tesla.Middleware.RequestIdForwarder
  alias Tesla.Env

  test "does nothing when there is no :logger_metadata in proccess dict" do
    original_env = %Env{}
    assert {:ok, env} = RequestIdForwarder.call(original_env, [], "http://some.url")
    assert env == original_env
  end

  test "does nothing when there is no :request_id in logger metadata" do
    Logger.metadata(other_key: "value")

    original_env = %Env{}
    assert {:ok, env} = RequestIdForwarder.call(original_env, [], "http://some.url")
    assert env == original_env
  end

  test "does nothing when there is a :request_id with wrong type" do
    Logger.metadata(request_id: :wrong_value)

    original_env = %Env{}
    assert {:ok, env} = RequestIdForwarder.call(original_env, [], "http://some.url")
    assert env == original_env
  end

  test "adds 'x-request-id' header when request_id is found in process dictionary" do
    Logger.metadata(request_id: "request_id")

    original_env = %Env{headers: [{"original_headers", "value"}]}
    assert {:ok, env} = RequestIdForwarder.call(original_env, [], "http://some.url")
    assert env.headers == original_env.headers ++ [{"x-request-id", "request_id"}]
  end
end
