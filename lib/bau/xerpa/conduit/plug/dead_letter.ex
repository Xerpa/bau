defmodule Bau.Xerpa.Conduit.Plug.DeadLetter do
  use Conduit.Plug.Builder

  @moduledoc """
  Since Conduit currently cannot reject a message with requeue=false,
  we need this to emulate that behaviour...
  """

  def init(opts) do
    # Fail if opts are missing
    _ = Keyword.fetch!(opts, :publish_to)
    _ = Keyword.fetch!(opts, :broker)

    opts
  end

  @doc """
  Publishes messages that were nacked or raised an exception to a
  dead letter destination.
  """
  def call(message, next, opts) do
    message = next.(message)

    case message.status do
      :ack -> message
      status -> reject(message, status, opts)
    end
  rescue
    error ->
      message
      |> put_header("exception", Exception.format(:error, error))
      |> reject(:reject, opts)

      reraise error, System.stacktrace()
  end

  @spec reject(Conduit.Message.t(), :nack | :reject, Keyword.t()) :: Conduit.Message.t()
  defp reject(message, action, opts) do
    broker = Keyword.get(opts, :broker)
    publish_to = Keyword.get(opts, :publish_to)

    original_routing_key =
      Message.get_header(message, "x-original-routing-key") ||
        Message.get_header(message, "routing_key")

    message
    |> put_header("x-original-routing-key", original_routing_key)
    |> broker.publish(publish_to, opts)

    case action do
      :nack ->
        # in this case, it'll be requeued...
        message

      :reject ->
        # acks message so it won't be requeued...
        ack(message)
    end
  end
end
