defmodule Bau.Xerpa.Conduit.Plug.DeadLetterTest do
  use ExUnit.Case

  alias Conduit.Message

  defmodule Broker do
    def publish(message, name, opts) do
      send(self(), {:publish, name, message, opts})
    end
  end

  describe "when the message is rejected" do
    defmodule RejectDeadLetter do
      use Conduit.Subscriber
      plug(Bau.Xerpa.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(message, _) do
        %{message | status: :reject}
      end
    end

    test "it publishes the message to the dead letter destination and acks the message" do
      routing_key = "routing_key"
      msg = Message.put_header(%Message{}, "routing_key", routing_key)
      assert %Message{status: :ack} = RejectDeadLetter.run(msg)

      assert_received {:publish, :error, dlq_msg = %Message{}, broker: Broker, publish_to: :error}
      assert Message.get_header(dlq_msg, "routing_key") == routing_key
      assert Message.get_header(dlq_msg, "x-original-routing-key") == routing_key
    end

    test "it preserves x-original-routing-key when present" do
      routing_key = "routing_key"
      original_routing_key = "original_routing_key"

      msg =
        %Message{}
        |> Message.put_header("routing_key", routing_key)
        |> Message.put_header("x-original-routing-key", original_routing_key)

      assert %Message{status: :ack} = RejectDeadLetter.run(msg)

      assert_received {:publish, :error, dlq_msg = %Message{}, broker: Broker, publish_to: :error}
      assert Message.get_header(dlq_msg, "routing_key") == routing_key
      assert Message.get_header(dlq_msg, "x-original-routing-key") == original_routing_key
    end
  end

  describe "when the message is nacked" do
    defmodule NackedDeadLetter do
      use Conduit.Subscriber
      plug(Bau.Xerpa.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(message, _) do
        nack(message)
      end
    end

    test "it publishes the message to the dead letter destination and nacks the message" do
      assert %Message{status: :nack} = NackedDeadLetter.run(%Message{})

      assert_received {:publish, :error, %Message{}, broker: Broker, publish_to: :error}
    end

    test "it preserves x-original-routing-key when present" do
      routing_key = "routing_key"
      original_routing_key = "original_routing_key"

      msg =
        %Message{}
        |> Message.put_header("routing_key", routing_key)
        |> Message.put_header("x-original-routing-key", original_routing_key)

      assert %Message{status: :nack} = NackedDeadLetter.run(msg)

      assert_received {:publish, :error, dlq_msg = %Message{}, broker: Broker, publish_to: :error}
      assert Message.get_header(dlq_msg, "routing_key") == routing_key
      assert Message.get_header(dlq_msg, "x-original-routing-key") == original_routing_key
    end
  end

  describe "when the message has errored" do
    defmodule ErroredDeadLetter do
      use Conduit.Subscriber
      plug(Bau.Xerpa.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(_message, _opts), do: raise("failure")
    end

    test "it publishes the message to the dead letter destination and reraises the error" do
      assert_raise(RuntimeError, "failure", fn ->
        ErroredDeadLetter.run(%Message{})
      end)

      assert_received {:publish, :error, %Message{} = message, broker: Broker, publish_to: :error}

      assert Message.get_header(message, "exception") =~ "failure"
    end

    test "it preserves x-original-routing-key when present" do
      routing_key = "routing_key"
      original_routing_key = "original_routing_key"

      msg =
        %Message{}
        |> Message.put_header("routing_key", routing_key)
        |> Message.put_header("x-original-routing-key", original_routing_key)

      assert_raise(RuntimeError, "failure", fn ->
        ErroredDeadLetter.run(msg)
      end)

      assert_received {:publish, :error, dlq_msg = %Message{}, broker: Broker, publish_to: :error}
      assert Message.get_header(dlq_msg, "routing_key") == routing_key
      assert Message.get_header(dlq_msg, "x-original-routing-key") == original_routing_key
    end
  end

  describe "when the message is successful" do
    defmodule AckDeadLetter do
      use Conduit.Subscriber
      plug(Bau.Xerpa.Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error)

      def process(message, _opts), do: message
    end

    test "it does not send a dead letter" do
      assert %Message{status: :ack} = AckDeadLetter.run(%Message{})

      refute_received {:publish, _, %Message{}, _}
    end
  end
end
