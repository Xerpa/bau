defmodule Bau.Xerpa.Conduit.Plug.ParseJSON do
  use Conduit.Plug.Builder

  @moduledoc """
  Like `Conduit.Plug.Parse`, but non-explosive on parse failures.
  """

  require Logger

  def call(message, next, _opts) do
    request_id = get_header(message, "x-request-id")
    correlation_id = message.correlation_id
    queue = message.source
    exchange = get_header(message, "exchange")

    case Jason.decode(message.body) do
      {:ok, decoded} ->
        message
        |> put_content_type("application/json")
        |> put_body(decoded)
        |> next.()

      {:error, error} ->
        msg = Exception.format(:error, error)

        Logger.error("invalid json message. discarding.\n#{msg}",
          request_id: request_id,
          correlation_id: correlation_id,
          queue: queue,
          exchange: exchange
        )

        %{message | status: :reject}
    end
  end
end
