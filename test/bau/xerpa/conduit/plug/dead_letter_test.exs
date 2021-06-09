defmodule Bau.Xerpa.Conduit.Plug.DeadLetterTest do
  use ExUnit.Case

  alias Conduit.Message

  defmodule Broker do
    def publish(message, name, opts) do
      send(self(), {:publish, name, message, opts})
    end
  end

  defmodule ParseJSONDeadLetterRoundtrip do
    use Conduit.Subscriber

    def process(message, _opts) do
      send(self(), {:process_message, message})
      succeed? = Conduit.Message.get_header(message, "succeed") == "true"

      if succeed? do
        message
      else
        %{message | status: :reject}
      end
    end
  end

  defmodule IntegrationBroker do
    use Conduit.Broker, otp_app: :bau_test

    pipeline :error_handling do
      plug(Bau.Xerpa.Conduit.Plug.DeadLetter,
        publish_to: :error,
        broker: __MODULE__
      )
    end

    pipeline :deserialize do
      plug(Bau.Xerpa.Conduit.Plug.ParseJSON)
    end

    pipeline :serialize do
      plug(Conduit.Plug.Format)
    end

    incoming Bau.Xerpa.Conduit.Plug.DeadLetterTest do
      pipe_through([:error_handling, :deserialize])

      subscribe(
        :roundtrip,
        ParseJSONDeadLetterRoundtrip,
        from: "queue"
      )
    end

    outgoing do
      pipe_through([:serialize])
      publish(:error, exchange: "dlx")
    end
  end

  # alias Bau.Xerpa.Conduit.Plug.DeadLetterTest.IntegrationBroker

  describe "parse json <-> dead letter roundtrip" do
    test "can reprocess json messages" do
      Application.put_env(:bau_test, IntegrationBroker, adapter: Conduit.TestAdapter)
      routing_key = "routing_key"

      original_decoded_body = %{
        "some_key" => ["value", 10]
      }

      original_encoded_body = Jason.encode!(original_decoded_body)

      msg =
        %Message{}
        |> Message.put_header("routing_key", routing_key)
        |> Message.put_content_type("application/json")
        |> Message.put_body(original_encoded_body)

      IntegrationBroker.receives(:roundtrip, msg)

      assert_received {:publish, IntegrationBroker, :error, dlq_msg = %Message{},
                       [adapter: Conduit.TestAdapter],
                       exchange: "dlx",
                       skip_parse_json?: true,
                       publish_to: :error,
                       broker: IntegrationBroker}

      assert_received {:process_message, %Message{body: %{}}}

      assert dlq_msg.body == original_encoded_body
      assert dlq_msg.status == :reject

      reprocessed_dlq_msg =
        dlq_msg
        |> Message.put_header("succeed", "true")
        |> Map.put(:status, :ack)

      IntegrationBroker.receives(:roundtrip, reprocessed_dlq_msg)

      assert_received {:process_message, %Message{body: %{}}}
      refute_received {:publish, IntegrationBroker, _, _, _, _}
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

      assert_received {:publish, :error, dlq_msg = %Message{},
                       skip_parse_json?: true, broker: Broker, publish_to: :error}

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

      assert_received {:publish, :error, dlq_msg = %Message{},
                       skip_parse_json?: true, broker: Broker, publish_to: :error}

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

      assert_received {:publish, :error, %Message{},
                       skip_parse_json?: true, broker: Broker, publish_to: :error}
    end

    test "it preserves x-original-routing-key when present" do
      routing_key = "routing_key"
      original_routing_key = "original_routing_key"

      msg =
        %Message{}
        |> Message.put_header("routing_key", routing_key)
        |> Message.put_header("x-original-routing-key", original_routing_key)

      assert %Message{status: :nack} = NackedDeadLetter.run(msg)

      assert_received {:publish, :error, dlq_msg = %Message{},
                       skip_parse_json?: true, broker: Broker, publish_to: :error}

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

      assert_received {:publish, :error, %Message{} = message,
                       skip_parse_json?: true, broker: Broker, publish_to: :error}

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

      assert_received {:publish, :error, dlq_msg = %Message{},
                       skip_parse_json?: true, broker: Broker, publish_to: :error}

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
