defmodule Bau.Xerpa.Conduit.Plug.RequestId do
  use Conduit.Plug.Builder

  alias Bau.Xerpa.Tracing
  alias Conduit.Message

  require Logger

  def call(message, next, _opts) do
    message =
      case Message.get_header(message, "x-request-id") do
        "" <> request_id ->
          Tracing.put_request_id(request_id)
          message

        _ ->
          add_message_request_id(message)
      end

    next.(message)
  end

  defp add_message_request_id(message) do
    case Tracing.get_request_id() do
      "" <> request_id ->
        put_headers(message, %{"x-request-id" => request_id})

      _ ->
        message
    end
  end
end
